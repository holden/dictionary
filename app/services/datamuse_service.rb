class DatamuseService
  include HTTParty
  base_uri 'https://api.datamuse.com'

  def self.related_words(word)
    response = get("/words", query: { rel_trg: word })
    return [] unless response.success?
    
    response.parsed_response
  rescue StandardError => e
    Rails.logger.error "Datamuse API error for '#{word}': #{e.message}"
    []
  end
end 