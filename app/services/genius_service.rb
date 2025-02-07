class GeniusService
  include HTTParty
  base_uri 'https://api.genius.com'

  SCRAPING_API_KEY = Rails.application.credentials.zyte_api_key
  MAX_RETRIES = 3
  TIMEOUT = 35
  CONNECT_TIMEOUT = 5

  class ScrapingError < StandardError; end

  def self.search(query)
    new.search(query)
  end

  def initialize
    @access_token = Rails.application.credentials.genius.access_token
  end

  def search(query)
    response = self.class.get('/search', query: {
      q: query
    }, headers: auth_headers)

    return [] unless response.success?

    parse_search_results(response)
  end

  # Fetch lyrics content from Genius webpage
  def fetch_lyrics(url, metadata = nil)
    retries = 0
    
    begin
      Rails.logger.info "Fetching lyrics content for #{url}"
      html = fetch_page_content(url)
      content = parse_lyrics_content(html)
      
      return nil unless content

      # Merge the content with the metadata from the API
      content.merge(metadata: { genius: metadata }) if metadata
      content
    rescue Net::ReadTimeout => e
      Rails.logger.error "Timeout error fetching lyrics: #{e.message}"
      retry if (retries += 1) <= MAX_RETRIES
      nil
    rescue StandardError => e
      Rails.logger.error "Lyrics scraping error: #{e.message}"
      retry if (retries += 1) <= MAX_RETRIES
      nil
    end
  end

  private

  def auth_headers
    {
      'Authorization' => "Bearer #{@access_token}"
    }
  end

  def parse_search_results(response)
    response['response']['hits'].map do |hit|
      result = hit['result']
      {
        title: result['title'],
        artist: result['primary_artist']['name'],
        source_url: result['url'],
        source_title: result['title'],
        year_written: result['release_date_components']&.fetch('year', nil),
        attribution_text: result['primary_artist']['name'],
        metadata: {
          genius: result  # Store the complete API response
        }
      }
    end
  end

  # Scraping methods moved from LyricsScrapingService
  def fetch_page_content(url)
    uri = URI('https://api.zyte.com/v1/extract')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = CONNECT_TIMEOUT
    http.read_timeout = TIMEOUT
    
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(SCRAPING_API_KEY, '')
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    
    request.body = {
      url: url,
      browserHtml: true
    }.to_json
    
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      error_info = JSON.parse(response.body) rescue { "error" => response.body }
      Rails.logger.error "Zyte API response: #{error_info.inspect}"
      raise ScrapingError, "HTTP Request failed: #{response.code} - #{error_info}"
    end
    
    response_data = JSON.parse(response.body)
    html_content = response_data['browserHtml']
    
    if html_content.blank?
      Rails.logger.error "No HTML content found in response: #{response_data.keys}"
    end
    
    html_content
  end

  def parse_lyrics_content(html)
    return nil if html.blank?
    
    doc = Nokogiri::HTML(html)
    
    lyrics_containers = doc.css('[data-lyrics-container="true"]')
    return nil if lyrics_containers.empty?

    content = lyrics_containers.map do |container|
      container.inner_html.gsub(/<br>/, "\n")
    end.join("\n\n")

    content = Nokogiri::HTML(content).text
      .gsub(/\[.*?\]/, '')  # Remove [Verse], [Chorus] etc.
      .gsub(/\s+/, ' ')     # Normalize whitespace
      .strip

    return nil if content.blank?

    { content: content }
  end
end 