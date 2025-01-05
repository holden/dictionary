class ConceptNetService
  include HTTParty
  base_uri 'http://api.conceptnet.io'
  
  def self.lookup(term)
    # Clean the term - remove punctuation and downcase
    clean_term = term.downcase.gsub(/[^\w\s]/, '')
    
    # Try a simple search first
    response = get("/search", query: {
      q: clean_term,
      limit: 1,
      filter: '/c/en'  # Only English concepts
    })
    
    if response.success? && response['edges'].any?
      # Get the first matching concept
      concept = response['edges'].first['start']
      return {
        'id' => concept['@id'],
        'edges' => response['edges']
      }
    end
    
    nil
  rescue StandardError => e
    Rails.logger.error "ConceptNet API error for '#{term}': #{e.message}"
    nil
  end
end 