require 'nokogiri'
require 'open-uri'

puts "Starting Devils Dictionary import..."

# Create or find Ambrose Bierce
ambrose_bierce = Topic.find_or_create_by!(
  title: "Ambrose Bierce",
  type: "Person"
)

# Create or find the Devil's Dictionary
devils_dictionary = Book.find_or_create_by!(
  title: "The Devil's Dictionary",
  author: ambrose_bierce,
  published_date: Date.new(1911)
)

# Clear existing definitions from this source
Definition.where(source: devils_dictionary).destroy_all

# Fetch and parse the Project Gutenberg content
url = "https://www.gutenberg.org/files/972/972-h/972-h.htm"
doc = Nokogiri::HTML(URI.open(url))

# Find the dictionary content - it's in <p> tags between the preface and end
dictionary_entries = doc.css('body p').select do |p|
  text = p.text.strip
  text.match?(/^[A-Z]+,\s+[a-z]+\.\s+/) # Matches pattern like "WORD, n. Definition"
end

puts "Found #{dictionary_entries.length} potential entries"

dictionary_entries.each do |entry|
  text = entry.text.strip
  
  # Parse the entry
  if text =~ /^([A-Z]+),\s+([a-z\.]+)\.\s+(.+)/m
    word = $1.strip
    part_of_speech = $2.strip
    definition = $3.strip

    # Determine type based on content analysis
    type = case definition.downcase
           when /\b(person|man|woman|author|king|queen)\b/ then "Person"
           when /\b(building|tool|weapon|structure|device)\b/ then "Thing"
           when /\b(action|activity|process|movement)\b/ then "Action"
           when /\b(place|location|country|city)\b/ then "Place"
           when /\b(event|battle|ceremony|occurrence)\b/ then "Event"
           else "Concept"
           end

    puts "Importing: #{word} (#{type})"
    
    # Create the topic
    topic = Topic.find_or_create_by!(
      title: word,
      type: type
    )

    # Create the definition
    Definition.create!(
      topic: topic,
      author: ambrose_bierce,
      source: devils_dictionary,
      content: definition
    )
  end
end

total_definitions = Definition.where(source: devils_dictionary).count
puts "Devils Dictionary import completed successfully!"
puts "Total definitions imported: #{total_definitions}" 