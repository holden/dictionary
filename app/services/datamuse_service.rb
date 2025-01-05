class DatamuseService
  include HTTParty
  base_uri 'https://api.datamuse.com'

  def self.related_words(word)
    Rails.logger.info "Fetching Datamuse related words for: #{word}"
    
    response = get("/words", query: { rel_trg: word })
    unless response.success?
      Rails.logger.error "Datamuse API error: #{response.code} - #{response.body}"
      return []
    end
    
    results = response.parsed_response
    Rails.logger.info "Found #{results.size} related words for #{word}"
    results
  rescue StandardError => e
    Rails.logger.error "Datamuse API error for '#{word}': #{e.message}"
    []
  end
end 