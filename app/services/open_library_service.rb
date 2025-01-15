require 'net/http'
require 'json'
require 'httparty'

class OpenLibraryService
  include HTTParty
  base_uri 'https://openlibrary.org'

  # New method for searching authors (used by people search)
  def search_authors(query)
    response = self.class.get('/search/authors.json', query: { q: query })
    
    return [] unless response.success?

    data = JSON.parse(response.body)
    data['docs'].map do |author|
      {
        'name' => author['name'],
        'key' => author['key']&.gsub('/authors/', ''),
        'birth_date' => author['birth_date'],
        'death_date' => author['death_date']
      }
    end
  rescue StandardError => e
    Rails.logger.error "OpenLibrary API error: #{e.message}"
    []
  end

  # Original method for looking up a single author (used by existing code)
  def self.search_author(name)
    response = get('/search/authors.json', query: { q: name })
    return nil unless response.success?

    data = JSON.parse(response.body)
    return nil if data['docs'].empty?

    author = data['docs'].first
    {
      'name' => author['name'],
      'key' => author['key']&.gsub('/authors/', ''),
      'birth_date' => author['birth_date'],
      'death_date' => author['death_date']
    }
  rescue StandardError => e
    Rails.logger.error "OpenLibrary API error: #{e.message}"
    nil
  end

  # Original method for looking up books (used by Book model)
  def self.lookup_book(title, author = nil)
    query = { q: title }
    query[:author] = author if author.present?
    
    response = get('/search.json', query: query)
    return nil unless response.success?

    docs = response['docs']
    return nil if docs.empty?

    docs.first
  rescue StandardError => e
    Rails.logger.error "OpenLibrary API error: #{e.message}"
    nil
  end
end 