require 'nokogiri'
require 'httparty'

class SamuelJohnsonService
  BASE_URL = 'https://johnsonsdictionaryonline.com'
  SEARCH_URL = "#{BASE_URL}/views/search.php"

  class << self
    def lookup_definition(word)
      # Normalize the term (remove spaces, punctuation)
      normalized_term = normalize_term(word)
      
      Rails.logger.debug "Searching for term: #{normalized_term}"
      
      # Make the search request
      response = HTTParty.get(
        SEARCH_URL,
        query: {
          term: normalized_term,
          searchType: 'Headword',
          edition: 'both',
          type: 'Text',
          view: 'both'
        },
        headers: {
          'Accept' => 'text/html',
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        follow_redirects: true
      )

      Rails.logger.debug "Johnson Dictionary response status: #{response.code}"
      Rails.logger.debug "Response URL: #{response.request.last_uri}"
      Rails.logger.debug "Response body preview: #{response.body[0..1000]}"
      return nil unless response.success?

      # Parse the HTML response
      doc = Nokogiri::HTML(response.body)
      
      # Try to find the definition content
      definition_div = doc.css('div').find do |div|
        div.text.include?(normalized_term) && 
        (div.at_css('sjddef') || div.at_css('sense') || div.at_css('headword'))
      end

      Rails.logger.debug "Definition div found: #{!!definition_div}"
      if definition_div
        Rails.logger.debug "Definition classes: #{definition_div['class']}"
        Rails.logger.debug "Definition content preview: #{definition_div.text[0..200]}"
      end
      return nil unless definition_div

      {
        headword: definition_div.at_css('headword')&.text&.strip,
        part_of_speech: definition_div.at_css('.gramGrp')&.text&.gsub(/[\[\]]/, '')&.strip,
        etymology: definition_div.at_css('.etym')&.text&.gsub(/[\[\]]/, '')&.strip,
        definition: definition_div.at_css('.sjddef, sense')&.text&.strip,
        quotes: definition_div.css('quotebibl').map { |q| 
          {
            text: q.at_css('quote')&.text&.strip,
            author: q.at_css('.author')&.text&.strip
          }
        },
        image_url: "https://johnsonsdictionaryonline.com/img/words/f1773-#{normalized_term}-1.png",
        raw_data: definition_div.to_html
      }
    end

    private

    def normalize_term(term)
      # Remove punctuation and spaces, convert to lowercase
      term.downcase.gsub(/[^a-z0-9]/, '')
    end
  end
end 