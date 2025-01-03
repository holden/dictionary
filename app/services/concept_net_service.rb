require 'net/http'
require 'uri'

class ConceptNetService
  include HTTParty
  base_uri 'https://api.conceptnet.io'
  
  def self.lookup_person(name)
    Rails.logger.info "ConceptNet looking up person: #{name}"
    
    response = get("/c/en/#{name.downcase.gsub(/[^a-z0-9]/, '_')}")
    
    if response.success?
      data = response.parsed_response
      Rails.logger.info "ConceptNet response: #{data.inspect}"
      
      # Get the ID from the correct place in the response
      concept_id = data["@id"] || data["edges"]&.first&.dig("start", "@id")
      return nil unless concept_id

      # Skip if it looks like a company or media entity
      return nil if concept_id.to_s.include?("_media") || 
                   concept_id.to_s.include?("_company") || 
                   concept_id.to_s.include?("_corporation")

      # Check if it's actually a person by looking at edges
      edges = data["edges"] || []
      is_person = edges.any? do |edge|
        edge["rel"]["label"] == "IsA" && 
        (edge["end"]["label"].downcase.include?("person") || 
         edge["end"]["label"].downcase.include?("author") ||
         edge["end"]["label"].downcase.include?("writer"))
      end

      if is_person
        Rails.logger.info "Found person in ConceptNet: #{concept_id}"
        {
          "id" => concept_id,
          "name" => name.titleize,
          "description" => extract_description(edges)
        }
      else
        Rails.logger.info "Not identified as person in ConceptNet"
        nil
      end
    else
      Rails.logger.error "ConceptNet API error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "ConceptNet error: #{e.message}"
    nil
  end

  def self.lookup(term)
    response = get("/c/en/#{term.downcase.gsub(/[^a-z0-9]/, '_')}")
    return nil unless response.success?
    
    data = response.parsed_response
    return nil unless data

    # Get the ID from the correct place
    concept_id = data["@id"] || data["edges"]&.first&.dig("start", "@id")
    return nil unless concept_id

    {
      "id" => concept_id,
      "name" => data["label"] || term,
      "edges" => data["edges"]
    }
  end

  private

  def self.extract_description(edges)
    description_edge = edges.find { |e| e["rel"]["label"] == "HasDescription" }
    description_edge&.dig("end", "label")
  end
end 