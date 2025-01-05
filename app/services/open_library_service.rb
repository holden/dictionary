class OpenLibraryService
  include HTTParty
  base_uri 'https://openlibrary.org'

  def self.lookup_author(name)
    # Try both search endpoints for better results
    author = search_authors(name) || search_authors_alt(name)
    return nil unless author

    # Return the key in the format we want
    {
      'key' => author['key']&.sub('/authors/', ''),
      'name' => author['name'],
      'birth_date' => author['birth_date'],
      'death_date' => author['death_date']
    }
  end

  def self.lookup_book(title, author_name = nil)
    query = { q: title }
    query[:author] = author_name if author_name.present?

    response = get("/search.json", query: query)
    return nil unless response.success?

    docs = response.parsed_response['docs']
    return nil if docs.empty?

    # Try to find exact match first
    exact_match = docs.find { |doc| doc['title']&.downcase == title.downcase }
    book = exact_match || docs.first

    {
      'key' => book['key'],
      'title' => book['title'],
      'publish_date' => book['publish_date']
    }
  end

  private

  def self.search_authors(name)
    response = get("/search/authors.json", query: { q: name })
    return nil unless response.success?

    docs = response.parsed_response['docs']
    return nil if docs.empty?

    # Try exact match first
    docs.find { |doc| doc['name']&.downcase == name.downcase } || docs.first
  end

  def self.search_authors_alt(name)
    # Try alternative endpoint
    response = get("/authors/_search", query: { q: name })
    return nil unless response.success?

    docs = response.parsed_response['docs']
    return nil if docs.empty?

    docs.first
  end
end 