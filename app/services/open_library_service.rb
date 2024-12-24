class OpenLibraryService
  include HTTParty
  base_uri 'https://openlibrary.org/api'

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
end 