require 'nokogiri'
require 'open-uri'

puts "Starting New Devil's Dictionary import..."

# Create or find The Verge website as source
the_verge = Website.find_or_create_by!(
  title: "The Verge",
  url: "https://www.theverge.com/a/new-devils-dictionary"
)

# Clear existing definitions from this source
Definition.where(source: the_verge).destroy_all

# Fetch and parse the content
url = "https://www.theverge.com/a/new-devils-dictionary"
doc = Nokogiri::HTML(URI.open(url))

puts "\nAttempting to find dictionary entries..."
entries = []

# Try a more lenient regex pattern
doc.css('p').each do |p|
  text = p.text.strip
  
  if text =~ /([A-Za-z0-9_-]+)\s*\(([^)]+)\):\s*(.+)/
    word = $1.strip
    part_of_speech = $2.strip
    definition = $3.strip
    
    # Determine type based on content analysis
    type = case definition.downcase
           when /\b(person|man|woman|author|king|queen|company|ceo)\b/ then "Person"
           when /\b(building|tool|weapon|structure|device|app|platform|phone|computer)\b/ then "Thing"
           when /\b(action|activity|process|movement|posting|tweeting|sharing)\b/ then "Action"
           when /\b(place|location|country|city|website|network)\b/ then "Place"
           when /\b(event|battle|ceremony|occurrence|launch|update)\b/ then "Event"
           else "Concept"
           end

    puts "Found potential entry: #{word} (#{type})"
    entries << {
      title: word,
      type: type,
      definition: definition
    }
  end
end

puts "\nFound #{entries.length} potential entries"

if entries.empty?
  puts "No entries found. Please check the HTML structure and update the selectors."
else
  entries.each do |entry|
    puts "Importing: #{entry[:title]} (#{entry[:type]})"
    
    # Find or initialize topic with case-insensitive lookup
    topic = Topic.where("LOWER(title) = LOWER(?)", entry[:title]).first
    
    if topic
      # If topic exists but has different type, skip it
      if topic.type != entry[:type]
        puts "  Skipping: Topic exists with different type (#{topic.type})"
        next
      end
    else
      # Create new topic if it doesn't exist
      topic = Topic.create!(
        title: entry[:title],
        type: entry[:type]
      )
      puts "  Created new topic: #{topic.title}"
    end

    # Create definition only if it doesn't exist for this source
    existing_definition = Definition.joins(:rich_text_content)
                                  .where(topic: topic, source: the_verge)
                                  .where("action_text_rich_texts.body = ?", entry[:definition])
                                  .first

    unless existing_definition
      Definition.create!(
        topic: topic,
        source: the_verge,
        content: entry[:definition]
      )
      puts "  Added new definition"
    end
  end
end

total_definitions = Definition.where(source: the_verge).count
puts "\nNew Devil's Dictionary import completed!"
puts "Total definitions imported: #{total_definitions}" 