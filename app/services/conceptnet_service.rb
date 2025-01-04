class ConceptnetService
  include HTTParty
  base_uri 'http://api.conceptnet.io'
  
  def self.search(term)
    response = get("/c/en/#{CGI.escape(term)}")
    
    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "ConceptNet API error: #{response.code} - #{response.message}"
      {}
    end
  rescue StandardError => e
    Rails.logger.error "ConceptNet API error: #{e.message}"
    {}
  end
end 