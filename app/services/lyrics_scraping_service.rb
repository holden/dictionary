class LyricsScrapingService
  API_KEY = Rails.application.credentials.zyte_api_key
  MAX_RETRIES = 3
  TIMEOUT = 35  # Match their successful response time of ~34 seconds
  CONNECT_TIMEOUT = 5

  class ScrapingError < StandardError; end

  class << self
    def fetch_content(url)
      retries = 0
      
      begin
        Rails.logger.info "Fetching lyrics page content: #{url}"
        html = fetch_page(url)
        parse_content(html)
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

    def fetch_page(url)
      uri = URI('https://api.zyte.com/v1/extract')
      
      # Configure HTTP client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = CONNECT_TIMEOUT
      http.read_timeout = TIMEOUT
      
      # Create and configure request
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(API_KEY, '')
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      
      # Match exactly what works in their logs
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

    def parse_content(html)
      return nil if html.blank?
      
      doc = Nokogiri::HTML(html)
      
      # Genius lyrics are typically in multiple containers
      lyrics_containers = doc.css('[data-lyrics-container="true"]')
      return nil if lyrics_containers.empty?

      # Combine all lyrics containers and clean up the text
      content = lyrics_containers.map do |container|
        container.inner_html.gsub(/<br>/, "\n")
      end.join("\n\n")

      # Clean up the text
      content = Nokogiri::HTML(content).text
        .gsub(/\[.*?\]/, '')  # Remove [Verse], [Chorus] etc.
        .gsub(/\s+/, ' ')     # Normalize whitespace
        .strip

      return nil if content.blank?

      {
        content: content,
        source_title: title,  # Add the title to the returned hash
        extracted_at: Time.current.iso8601
      }
    end
  end
end 