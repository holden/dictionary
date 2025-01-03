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
    response = get("/search/authors.json", query: { q: name })
    return nil unless response.success?
    
    data = JSON.parse(response.body)
    author = data["docs"]&.first
    return nil unless author
    
    {
      "key" => author["key"],
      "name" => author["name"],
      "bio" => author["bio"]
    }
  end
end 