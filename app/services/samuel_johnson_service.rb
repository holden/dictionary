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
      cache_key = cache_key_for(normalized_term)
      retries = 0
      
      begin
        Rails.logger.info "Fetching Johnson's Dictionary definition for: #{normalized_term}"
        
        # First try to get from cache
        Rails.logger.debug "Checking cache for key: #{cache_key}"
        cached = Rails.cache.read(cache_key)
        if cached
          Rails.logger.debug "Cache hit for #{cache_key}"
          return cached
        end

        # Fetch the search results page
        html = fetch_page(SEARCH_URL, {
          term: normalized_term,
          searchType: 'Headword',
          edition: 'both',
          submit: 'Search'
        })

        # Parse the definition
        result = parse_definition(html, normalized_term)
        
        if result
          Rails.logger.debug "Caching result for #{cache_key}"
          Rails.cache.write(cache_key, result, expires_in: 1.week)
        end

        result
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
        div.text.include?(term) || 
        (div.at_css('headword') || div.at_css('sense') || div.at_css('.sjddef'))
      end

      Rails.logger.debug "Definition div found: #{!!definition_div}"
      return nil unless definition_div

      # Extract the definition components
      headword = definition_div.at_css('headword')&.text&.strip
      pos = definition_div.at_css('.gramGrp pos, .gramGrp')&.text&.gsub(/[\[\]]/, '')&.strip
      etymology = definition_div.at_css('.etym')&.text&.strip
      definition = definition_div.at_css('.sjddef')&.text&.strip
      quotes = definition_div.css('quotebibl').map do |q| 
        {
          text: q.at_css('quote')&.text&.strip,
          author: q.at_css('.author em')&.text&.strip,
          work: q.at_css('.title em')&.text&.strip
        }
      end

      # Format the content HTML
      content_html = format_content_html(headword, pos, etymology, definition, quotes, term)

      {
        headword: headword,
        part_of_speech: pos,
        etymology: etymology,
        definition: definition,
        quotes: quotes,
        image_url: "https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png",
        raw_data: definition_div.to_html,
        content_html: content_html,
        metadata: {
          johnson_dictionary: {
            headword: headword,
            part_of_speech: pos,
            etymology: etymology,
            quotes: quotes,
            image_urls: {
              '1755' => "https://johnsonsdictionaryonline.com/img/words/f1755-#{term}-1.png",
              '1773' => "https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png"
            },
            raw_html: definition_div.to_html,
            extracted_at: Time.current.iso8601
          }
        }
      }
    end

    def normalize_term(term)
      term.downcase.gsub(/[^a-z0-9]/, '')
    end

    def format_content_html(headword, pos, etymology, definition, quotes, term)
      <<~HTML
        <div class="johnson-definition">
          <div class="headword">
            <h3>#{headword}</h3>
            <span class="part-of-speech">#{pos}</span>
          </div>
          
          <div class="etymology">
            #{etymology}
          </div>
          
          <div class="definition">
            #{definition}
          </div>
          
          #{quotes.map do |quote|
            <<~QUOTE
              <blockquote class="quote">
                <p>#{quote[:text]}</p>
                <cite>#{quote[:author]}#{quote[:work] ? ", #{quote[:work]}" : ""}</cite>
              </blockquote>
            QUOTE
          end.join("\n")}
          
          <figure class="dictionary-image">
            <img src="https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png" alt="Johnson's Dictionary entry for #{headword}">
          </figure>
        </div>
      HTML
    end

    def cache_key_for(term)
      "johnson_dictionary/#{term.downcase}"
    end
  end
end 