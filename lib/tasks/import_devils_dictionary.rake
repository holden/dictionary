require 'nokogiri'
require 'open-uri'

namespace :dictionary do
  desc "Import entries from Devil's Dictionary"
  task import: :environment do
    def parse_entry(entry_text)
      # Extract title and definition
      if entry_text =~ /^([A-Z]+),\s+([a-z\.]+)\.\s+(.+)/i
        {
          title: $1.strip,
          type: determine_type($3),
          definition: $3.strip
        }
      end
    end

    def determine_type(definition)
      # Simple heuristic - can be improved
      case definition.downcase
      when /\b(person|man|woman|author|king|queen)\b/
        "Person"
      when /\b(building|tool|weapon|structure|device)\b/
        "Thing"
      when /\b(action|activity|process|movement)\b/
        "Action"
      when /\b(place|location|country|city)\b/
        "Place"
      when /\b(event|battle|ceremony|occurrence)\b/
        "Event"
      else
        "Concept"
      end
    end

    puts "Starting import..."
    
    # Create Ambrose Bierce if not exists
    ambrose_bierce = Topic.find_or_create_by!(
      title: "Ambrose Bierce",
      type: "Person"
    )

    # Create or find the book
    devils_dictionary = Book.find_or_create_by!(
      title: "The Devil's Dictionary",
      author: ambrose_bierce,
      published_date: Date.new(1911)
    )

    # The actual import logic would go here
    # You would need to implement proper parsing logic
    # being careful about copyright considerations
    
    puts "Import completed!"
  end
end 