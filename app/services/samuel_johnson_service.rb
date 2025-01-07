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
        
        # Find or create Samuel Johnson as the author
        samuel_johnson = Person.find_or_create_by!(title: 'samuel johnson') do |person|
          person.slug = 'samuel-johnson'
        end

        # Find or create the dictionary as a source - simplified to avoid unique constraint issues
        dictionary = Website.find_or_create_by!(url: BASE_URL) do |website|
          website.title = "Johnson's Dictionary of the English Language"
          website.description = "First published in 1755 and written by Samuel Johnson"
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
        return nil unless result
        
        # Return with author and source information
        {
          content_html: result[:content_html],
          metadata: result[:metadata],
          author: samuel_johnson,
          source: dictionary
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
      definition_div = doc.at_css('#result_word')
      return nil unless definition_div

      # Extract basic components and clean up whitespace
      headword = definition_div.at_css('headword')&.text&.gsub(/\s+/, ' ')&.strip
      pos = definition_div.at_css('.gramGrp pos, pos')&.text&.gsub(/\s+/, ' ')&.strip
      etymology = definition_div.at_css('.etym')&.text&.gsub(/\s+/, ' ')&.gsub(/[\[\]]/, '')&.strip
      definition = definition_div.at_css('sjddef')&.text&.gsub(/\s+/, ' ')&.strip

      # Return nil if we don't have the minimum required data
      return nil unless headword.present? && definition.present?

      # Extract quotes with better handling of poetry-style quotes
      quotes = definition_div.css('quotebibl').map do |quote|
        if !quote.at_css('quote')
          # For poetry-style quotes, preserve intentional line breaks only
          text_nodes = []
          quote.children.each do |node|
            break if node.matches?('.bibl, br.bibl')
            if node.text?
              text_nodes << node.text.strip
            elsif node.name == 'br' && node['class'] == 'cit-verse'
              text_nodes << "\n"
            elsif node.name == 'em'
              text_nodes << node.text.strip
            end
          end
          quote_text = text_nodes.join(' ').gsub(/\s+/, ' ').strip
                                .split("\n").map(&:strip).join("\n")
        else
          # For regular quotes
          quote_text = quote.at_css('quote').text.gsub(/\s+/, ' ').strip
        end

        author = quote.at_css('.author em')&.text&.gsub(/[.]$/, '')&.strip
        work = quote.at_css('.title em')&.text&.gsub(/[.]$/, '')&.strip

        {
          text: quote_text,
          author: author,
          work: work
        }
      end.reject { |q| q[:text].blank? }

      # Format as simple HTML with clean whitespace
      content_html = <<~HTML
        <div class="johnson-definition">
          <h3>#{headword}</h3>
          <p>#{pos} #{etymology}</p>
          <p>#{definition}</p>
          #{quotes.map do |quote|
            lines = quote[:text].split("\n")
            text = if lines.length > 1
              lines.map { |line| "<p>#{line}</p>" }.join
            else
              "<p>#{quote[:text]}</p>"
            end
            <<~QUOTE.strip
              <blockquote>
                #{text}
                <cite>#{[quote[:author], quote[:work]].compact.join(", ")}</cite>
              </blockquote>
            QUOTE
          end.join("\n")}
          <figure class="dictionary-image">
            <img src="https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png" 
                 alt="Johnson's Dictionary entry for #{headword}"
                 loading="lazy">
          </figure>
        </div>
      HTML

      {
        content_html: content_html.strip,
        metadata: {
          johnson_dictionary: {
            headword: headword,
            part_of_speech: pos,
            etymology: etymology,
            quotes: quotes,
            image_url: "https://johnsonsdictionaryonline.com/img/words/f1773-#{term}-1.png",
            extracted_at: Time.current.iso8601
          }
        }
      }
    end

    def normalize_term(term)
      term.downcase.gsub(/[^a-z0-9]/, '')
    end
  end
end 