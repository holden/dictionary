require 'net/http'
require 'uri'

class ConceptNetService
  include HTTParty
  base_uri 'http://api.conceptnet.io'
  
  def self.lookup_person(name)
    response = get("/c/en/#{URI.encode_www_form_component(name.downcase)}")
    return nil unless response.success?
    
    data = JSON.parse(response.body)
    return nil unless data["edges"]&.any? { |e| e["rel"]["label"] == "IsA" && e["end"]["label"].downcase.include?("person") }
    
    {
      "id" => data["@id"],
      "name" => data["label"] || name,
      "description" => data["edges"]
        &.find { |e| e["rel"]["label"] == "DefinedAs" }
        &.dig("end", "label")
    }
  end
end 