require 'net/http'
require 'uri'

class ConceptNetService
  include HTTParty
  base_uri 'https://api.conceptnet.io'

  class Error < StandardError; end

  class << self
    def lookup_person(name)
      Rails.logger.info "ConceptNet looking up person: #{name}"
      
      response = get("/c/en/#{name.downcase.gsub(/[^a-z0-9]/, '_')}")
      
      if response.success?
        data = response.parsed_response
        Rails.logger.info "ConceptNet response: #{data.inspect}"
        
        return nil if company_or_media_entity?(data)
        return process_person_data(data, name) if person_data?(data)
        
        # Try search as fallback
        search_for_person(name)
      else
        Rails.logger.error "ConceptNet API error: #{response.code} - #{response.body}"
        nil
      end
    rescue => e
      Rails.logger.error "ConceptNet error: #{e.message}"
      nil
    end

    def lookup(term)
      response = get("/c/en/#{term.downcase.gsub(/[^a-z0-9]/, '_')}")
      return nil unless response.success?
      
      data = response.parsed_response
      return nil unless data

      concept_id = data["@id"] || data["edges"]&.first&.dig("start", "@id")
      return nil unless concept_id

      {
        "id" => concept_id,
        "name" => data["label"] || term,
        "edges" => data["edges"]
      }
    end

    private

    def company_or_media_entity?(data)
      id = data["id"] || data["@id"]
      return false unless id
      
      id.include?("_media") || 
      id.include?("_company") || 
      id.include?("_corporation")
    end

    def person_data?(data)
      edges = data["edges"] || []
      edges.any? do |edge|
        edge["rel"]["label"] == "IsA" && 
        (edge["end"]["label"].downcase.include?("person") || 
         edge["end"]["label"].downcase.include?("author") ||
         edge["end"]["label"].downcase.include?("writer"))
      end
    end

    def process_person_data(data, name)
      concept_id = data["@id"] || data["edges"]&.first&.dig("start", "@id")
      return nil unless concept_id

      Rails.logger.info "Found person in ConceptNet: #{concept_id}"
      {
        "id" => concept_id,
        "name" => name.titleize,
        "description" => extract_description(data["edges"] || [])
      }
    end

    def search_for_person(name)
      search_response = get("/search?node=/c/en&other=/c/en/person&rel=/r/IsA&text=#{URI.encode_www_form_component(name)}")
      
      return nil unless search_response.success?
      
      results = search_response.parsed_response["edges"]
      person_result = results&.find do |edge|
        start_concept = edge["start"]["label"].downcase
        start_concept.include?(name.downcase) && 
        !start_concept.include?("media") && 
        !start_concept.include?("company") && 
        !start_concept.include?("corporation")
      end

      if person_result
        {
          "id" => person_result["start"]["@id"],
          "name" => name.titleize,
          "description" => nil
        }
      end
    end

    def extract_description(edges)
      description_edge = edges.find { |e| e["rel"]["label"] == "HasDescription" }
      description_edge&.dig("end", "label")
    end
  end
end 