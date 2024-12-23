require 'net/http'
require 'uri'

class ConceptNetService
  BASE_URL = 'http://api.conceptnet.io'

  def self.lookup(term, language = 'en')
    new.lookup(term, language)
  end

  def lookup(term, language = 'en')
    formatted_term = format_term(term)
    uri = URI("#{BASE_URL}/c/#{language}/#{formatted_term}?limit=50")
    
    Rails.logger.info "ConceptNet API Request: #{uri}"
    
    # Create HTTP client that follows redirects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    
    # Make request and follow redirects (max 5 times)
    response = fetch_with_redirects(http, uri)
    Rails.logger.info "ConceptNet API Final Response Status: #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      Rails.logger.info "ConceptNet API Response: #{data['@id']}"
      data
    else
      Rails.logger.error "ConceptNet API Error: #{response.body}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "ConceptNet JSON Parse Error: #{e.message}"
    nil
  rescue URI::InvalidURIError => e
    Rails.logger.error "ConceptNet Invalid URI Error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "ConceptNet Unexpected Error: #{e.message}"
    nil
  end

  private

  def fetch_with_redirects(http, uri, limit = 5)
    raise ArgumentError, 'Too many redirects' if limit == 0

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    case response
    when Net::HTTPRedirection
      location = response['location']
      Rails.logger.info "Following redirect to: #{location}"
      new_uri = URI(location)
      new_http = Net::HTTP.new(new_uri.host, new_uri.port)
      new_http.use_ssl = new_uri.scheme == 'https'
      fetch_with_redirects(new_http, new_uri, limit - 1)
    else
      response
    end
  end

  def format_term(term)
    # Handle special characters and spaces properly for URLs
    ERB::Util.url_encode(term.downcase.strip.gsub(/\s+/, '_'))
  end
end 