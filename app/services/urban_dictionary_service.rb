class UrbanDictionaryService
  include HTTParty
  base_uri 'https://mashape-community-urban-dictionary.p.rapidapi.com'

  def self.search(term, limit: 1)
    Rails.logger.info "Starting Urban Dictionary search for: #{term}"
    
    Rails.cache.fetch("urban_dictionary/#{term}", expires_in: 1.hour) do
      begin
        response = get('/define', {
          query: { term: term },
          headers: {
            'x-rapidapi-host' => 'mashape-community-urban-dictionary.p.rapidapi.com',
            'x-rapidapi-key' => Rails.application.credentials.rapid_api_key
          }
        })

        return [] unless response.success?

        parsed_response = response.parsed_response
        return [] unless parsed_response['list'].present?

        definitions = parsed_response['list'].sort_by { |d| -d['thumbs_up'].to_i }
        
        definitions.take(limit).map do |definition|
          {
            content: definition['definition'],
            example: definition['example'],
            author: definition['author'],
            thumbs_up: definition['thumbs_up'],
            thumbs_down: definition['thumbs_down'],
            url: definition['permalink'],
            term_url: "https://www.urbandictionary.com/define.php?term=#{URI.encode_www_form_component(term)}"
          }
        end
      rescue => e
        Rails.logger.error "Urban Dictionary API error: #{e.class} - #{e.message}"
        []
      end
    end
  end
end 