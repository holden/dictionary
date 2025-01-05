require 'net/http'
require 'uri'

class ConceptNetService
  include HTTParty
  base_uri 'http://api.conceptnet.io'

  def self.lookup(term)
    # Add better error handling and retry logic
    response = get("/c/en/#{term.downcase.gsub(' ', '_')}")
    return nil unless response.success?

    # Return the parsed response if successful
    response.parsed_response
  rescue StandardError => e
    Rails.logger.error "ConceptNet API error for '#{term}': #{e.message}"
    nil
  end
end 