require 'net/http'
require 'json'
require 'httparty'

class OpenLibraryService
  include HTTParty
  base_uri 'https://openlibrary.org'

  def self.search_authors(query)
    response = get('/search/authors.json', query: { q: query })
    
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