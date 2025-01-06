require 'net/http'
require 'net/https'
require 'json'
require 'base64'

class BrainyQuotesService
  BASE_URL = 'https://www.brainyquote.com'
  API_KEY = Rails.application.credentials.zyte_api_key
  MAX_RETRIES = 3

  class AuthorNotFound < StandardError; end
  class QuoteNotFound < StandardError; end
  class ScrapingError < StandardError; end

  class << self
    def search(params)
      author = params[:author].to_s.downcase
      retries = 0
      
      begin
        author_slug = author.gsub(/[^a-z0-9\s]/, '').gsub(/\s+/, '-')
        author_url = "#{BASE_URL}/authors/#{author_slug}-quotes"
        
        Rails.logger.info "Fetching BrainyQuotes author page: #{author_url}"
        html = fetch_page(author_url)
        
        if page_has_quotes?(html)
          parse_quotes_page(html, author_url)
        else
          # Try search if direct URL fails
          search_url = "#{BASE_URL}/search_results?q=#{CGI.escape(author)}"
          Rails.logger.info "Author not found, trying search: #{search_url}"
          
          search_html = fetch_page(search_url)
          author_url = extract_author_url(search_html, author)
          
          raise AuthorNotFound, "No quotes found for author: #{author}" unless author_url
          
          Rails.logger.info "Found author URL: #{author_url}"
          html = fetch_page(author_url)
          parse_quotes_page(html, author_url)
        end
      rescue StandardError => e
        Rails.logger.error "BrainyQuotes error: #{e.message}"
        retry if (retries += 1) <= MAX_RETRIES && !e.is_a?(AuthorNotFound)
        []
      end
    end

    private

    def fetch_page(url)
      uri = URI('https://api.zyte.com/v1/extract')
      
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(API_KEY, '')
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      
      request.body = {
        url: url,
        browserHtml: true,
        javascript: true
      }.to_json
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 30
      
      response = http.request(request)
      
      unless response.is_a?(Net::HTTPSuccess)
        error_info = JSON.parse(response.body) rescue { "error" => response.body }
        Rails.logger.error "Zyte API response: #{error_info.inspect}"
        raise ScrapingError, "HTTP Request failed: #{response.code} - #{error_info}"
      end
      
      response_data = JSON.parse(response.body)
      # Use browserHtml instead of httpResponseBody
      response_data['browserHtml'] || ''
    end

    def page_has_quotes?(html)
      doc = Nokogiri::HTML(html)
      doc.css('.grid-item, .quoteContent').any?
    end

    def extract_author_url(html, author)
      doc = Nokogiri::HTML(html)
      
      author_link = doc.css('a').find do |link|
        href = link['href'].to_s.downcase
        text = link.text.to_s.downcase
        href.include?('/authors/') && (text.include?(author) || href.include?(author))
      end
      
      author_link && "#{BASE_URL}#{author_link['href']}"
    end

    def parse_quotes_page(html, author_url)
      doc = Nokogiri::HTML(html)
      quotes = []
      
      doc.css('.grid-item').each do |quote_div|
        begin
          quote_text = quote_div.at_css('.b-qt')&.text&.strip
          quote_link = quote_div.at_css('a[href*="/quotes/"]')
          next unless quote_text.present? && quote_link

          quote_url = quote_link['href']
          quote_id = quote_url.split('/').last

          # Get topics/tags
          topics = quote_div.css('.qt-chip').map(&:text).map(&:strip)
          attribution_text = doc.at_css('.bq-aut')&.text&.strip

          metadata = {
            brainyquote: {
              quote_id: quote_id,
              author_url: author_url,
              quote_url: quote_url.start_with?('http') ? quote_url : "#{BASE_URL}#{quote_url}",
              topics: topics,
              raw_html: quote_div.to_html,
              extracted_at: Time.current.iso8601
            }
          }

          quotes << {
            content: quote_text,
            attribution_text: attribution_text,
            source_url: metadata[:brainyquote][:quote_url],
            original_text: quote_text,
            original_language: 'en',
            citation: topics.join(', '),
            disputed: false,
            misattributed: false,
            metadata: metadata
          }
        rescue => e
          Rails.logger.error "Error parsing quote: #{e.message}"
          next
        end
      end

      Rails.logger.info "Found #{quotes.length} quotes"
      quotes
    end
  end
end 