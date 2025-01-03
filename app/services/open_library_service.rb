class OpenLibraryService
  include HTTParty
  base_uri 'https://openlibrary.org'

  def self.search(title)
    response = get('/search.json', query: { q: title })
    return nil unless response.success?

    docs = response.parsed_response['docs']
    return nil if docs.empty?

    book = docs.first
    {
      title: book['title'],
      openlibrary_id: book['key'],
      published_date: book['first_publish_date']&.to_date,
      author_name: book['author_name']&.first
    }
  rescue HTTParty::Error => e
    Rails.logger.error "OpenLibrary API error: #{e.message}"
    nil
  end

  def self.lookup_author(name)
    # First try direct author search
    response = get("/search/authors.json", query: {
      q: name,
      limit: 10
    })

    if response.success? && response["docs"].present?
      # Try exact match first
      exact_match = response["docs"].find { |doc| doc["name"].downcase == name.downcase }
      return format_author(exact_match) if exact_match

      # Try fuzzy match if no exact match
      best_match = response["docs"].find do |doc|
        doc_name = doc["name"].downcase
        name_parts = name.downcase.split
        name_parts.all? { |part| doc_name.include?(part) } &&
          !doc_name.include?("media") &&
          !doc_name.include?("company") &&
          !doc_name.include?("corporation")
      end
      
      return format_author(best_match) if best_match
    end

    # If no match found, try alternative author endpoint
    alt_response = get("/authors/search.json", query: {
      q: name,
      limit: 1
    })

    if alt_response.success? && alt_response["docs"].present?
      author = alt_response["docs"].first
      return format_author(author) unless author["name"].downcase.include?("media")
    end

    nil
  end

  private

  def self.format_author(author)
    return nil unless author

    {
      "key" => author["key"],
      "name" => author["name"],
      "birth_date" => author["birth_date"],
      "death_date" => author["death_date"],
      "bio" => author["bio"]
    }
  end
end 