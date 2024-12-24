class UrbanDictionaryService
  include HTTParty
  base_uri 'https://mashape-community-urban-dictionary.p.rapidapi.com'

  def self.search(term, limit: 2)
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

        Rails.logger.info "Urban Dictionary response status: #{response.code}"
        Rails.logger.info "Urban Dictionary response headers: #{response.headers.inspect}"
        Rails.logger.info "Urban Dictionary response body: #{response.body}"

        if !response.success?
          Rails.logger.error "Urban Dictionary API error: #{response.code} - #{response.body}"
          return []
        end

        parsed_response = response.parsed_response
        if !parsed_response['list'].present?
          Rails.logger.info "No definitions found for: #{term}"
          return []
        end

        definitions = parsed_response['list'].sort_by { |d| -d['thumbs_up'].to_i }
        Rails.logger.info "Found #{definitions.size} definitions, taking top #{limit}"
        
        definitions.take(limit).map do |definition|
          {
            content: definition['definition'],
            example: definition['example'],
            author: definition['author'],
            thumbs_up: definition['thumbs_up'],
            thumbs_down: definition['thumbs_down'],
            url: definition['permalink']
          }
        end
      rescue => e
        Rails.logger.error "Urban Dictionary API error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        []
      end
    end
  end
end 