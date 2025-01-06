require 'net/http'
require 'net/https'
require 'json'

class SamuelJohnsonService
  BASE_URL = 'https://johnsonsdictionaryonline.com'
  SEARCH_URL = "#{BASE_URL}/views/search.php"
  API_KEY = Rails.application.credentials.zyte_api_key
  MAX_RETRIES = 3

  class << self
    def lookup_definition(word)
      normalized_term = normalize_term(word)
      retries = 0
      
      begin
        Rails.logger.info "Fetching Johnson's Dictionary definition for: #{normalized_term}"
        
        # First try to get from cache
        cached = Rails.cache.read("johnson_dictionary/#{normalized_term}")
        return cached if cached

        # Fetch the search results page
        html = fetch_page(SEARCH_URL, {
          term: normalized_term,
          searchType: 'Headword',
          edition: 'both',
          submit: 'Search'
        })

        # Parse the definition
        result = parse_definition(html, normalized_term)
        return nil unless result
        
        # Cache successful results
        Rails.cache.write("johnson_dictionary/#{normalized_term}", result, expires_in: 1.week)

        # Return just what's needed for creating the definition
        {
          content_html: result[:content_html],
          metadata: result[:metadata]
        }
      rescue StandardError => e
        Rails.logger.error "Johnson's Dictionary error: #{e.message}"
        retry if (retries += 1) <= MAX_RETRIES
        nil
      end
    end

    private

    def fetch_page(url, params = {})
      uri = URI('https://api.zyte.com/v1/extract')
      
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(API_KEY, '')
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      
      full_url = params.any? ? "#{url}?#{URI.encode_www_form(params)}" : url
      
      request.body = {
        url: full_url,
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
        raise "HTTP Request failed: #{response.code} - #{error_info}"
      end
      
      response_data = JSON.parse(response.body)
      response_data['browserHtml'] || ''
    end

    def parse_definition(html, term)
      doc = Nokogiri::HTML(html)
      Rails.logger.debug "Parsing HTML for term: #{term}"
      
      # Find the definition content
      definition_div = doc.css('div').find do |div|
        div.text.include?(term) && 
        (div.at_css('headword') || div.at_css('sense') || div.at_css('.sjddef'))
      end

      Rails.logger.debug "Definition div found: #{!!definition_div}"
      return nil unless definition_div

      # Extract the definition components
      headword = definition_div.at_css('headword')&.text&.strip
      pos = definition_div.at_css('.gramGrp pos, .gramGrp')&.text&.gsub(/[\[\]]/, '')&.strip
      etymology = definition_div.at_css('.etym')&.text&.gsub(/[\[\]]/, '')&.strip
      definition = definition_div.at_css('.sjddef')&.text&.strip

      # Extract quotes more cleanly
      quotes = definition_div.css('quotebibl').map do |q| 
        {
          text: q.at_css('quote')&.text&.strip,
          author: q.at_css('.author em')&.text&.gsub(/[.]$/, ''),  # Remove trailing period
          work: q.at_css('.title em')&.text&.gsub(/[.]$/, '')      # Remove trailing period
        }
      end.reject { |q| q[:text].blank? }  # Remove empty quotes

      # Store metadata more concisely
      metadata = {
        johnson_dictionary: {
          edition: '1773',
          headword: headword,
          part_of_speech: pos,
          etymology: etymology,
          quotes: quotes,
          image_url: "https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png",
          extracted_at: Time.current.iso8601
        }
      }

      # Format the content HTML more cleanly
      content_html = <<~HTML
        <div class="johnson-definition">
          <header class="definition-header">
            <h3 class="headword">#{headword}</h3>
            <span class="part-of-speech">#{pos}</span>
            <div class="etymology">#{etymology}</div>
          </header>
          
          <div class="definition-body">
            #{definition}
          </div>
          
          #{quotes.map do |quote|
            <<~QUOTE
              <blockquote class="quote">
                <p>#{quote[:text]}</p>
                <cite>#{[quote[:author], quote[:work]].compact.join(", ")}</cite>
              </blockquote>
            QUOTE
          end.join("\n")}
          
          <figure class="dictionary-image">
            <img src="#{metadata[:johnson_dictionary][:image_url]}" 
                 alt="Johnson's Dictionary entry for #{headword}"
                 loading="lazy">
          </figure>
        </div>
      HTML

      {
        content_html: content_html,
        metadata: metadata
      }
    end

    def normalize_term(term)
      term.downcase.gsub(/[^a-z0-9]/, '')
    end
  end
end 