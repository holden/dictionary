class ConceptNetService
  include HTTParty
  base_uri 'https://api.conceptnet.io'

  def self.lookup_person(name)
    # First try exact match for person
    response = get("/c/en/#{name.downcase.gsub(/[^a-z0-9]/, '_')}")
    
    if response.success?
      data = response.parsed_response
      
      # Skip if it looks like a company or media entity
      return nil if data["id"].include?("_media") || 
                   data["id"].include?("_company") || 
                   data["id"].include?("_corporation")

      # Check if it's actually a person by looking at edges
      edges = data["edges"] || []
      is_person = edges.any? do |edge|
        edge["rel"]["label"] == "IsA" && 
        (edge["end"]["label"].downcase.include?("person") || 
         edge["end"]["label"].downcase.include?("author") ||
         edge["end"]["label"].downcase.include?("writer"))
      end

      return nil unless is_person

      {
        "id" => data["id"],
        "name" => name.titleize,
        "description" => extract_description(edges)
      }
    end

    # If no exact match, try search
    search_response = get("/search?node=/c/en&other=/c/en/person&rel=/r/IsA&text=#{URI.encode_www_form_component(name)}")
    
    if search_response.success?
      results = search_response.parsed_response["edges"]
      
      # Find best match that's actually a person
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
  end

  private

  def self.extract_description(edges)
    description_edge = edges.find { |e| e["rel"]["label"] == "HasDescription" }
    description_edge&.dig("end", "label")
  end
end 