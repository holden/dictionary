require 'net/http'
require 'uri'

class ConceptNetService
  BASE_URL = 'http://api.conceptnet.io'

  def self.lookup(term, language = 'en')
    new.lookup(term, language)
  end

  def lookup(term, language = 'en')
    formatted_term = format_term(term)
    base_id = "/c/#{language}/#{formatted_term}"
    
    # First try direct lookup
    uri = URI("#{BASE_URL}/c/#{language}/#{formatted_term}")
    response = make_request(uri)
    
    # If direct lookup fails or has no edges, try query endpoint
    if !response || !response['edges']&.any?
      uri = URI("#{BASE_URL}/query?node=#{base_id}&limit=50")
      response = make_request(uri)
    end

    return nil unless response

    # Log the response structure
    Rails.logger.debug "ConceptNet Response Structure:"
    Rails.logger.debug "Edges: #{response['edges']&.size}"
    if response['edges']&.any?
      Rails.logger.debug "Sample edge: #{response['edges'].first.inspect}"
    end

    # Add the @id to the response for compatibility
    response['@id'] = base_id
    response
  end

  def make_request(uri)
    Rails.logger.info "ConceptNet API Request: #{uri}"
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    
    response = fetch_with_redirects(http, uri)
    Rails.logger.info "ConceptNet API Final Response Status: #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      Rails.logger.info "ConceptNet API Response edges: #{data['edges']&.size}"
      data
    else
      Rails.logger.error "ConceptNet API Error: #{response.body}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "ConceptNet JSON Parse Error: #{e.message}"
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
    # Normalize the term
    term = term.downcase.strip
    
    # Handle special characters and spaces
    term.gsub(/[^a-z0-9\s]/i, '') # Remove special characters
        .gsub(/\s+/, '_')         # Replace spaces with underscores
  end
end 