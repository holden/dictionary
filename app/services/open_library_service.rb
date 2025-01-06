require 'net/http'
require 'json'

class OpenLibraryService
  BASE_URL = 'https://openlibrary.org'

  class << self
    def search_author(name)
      query = URI.encode_www_form_component(name)
      url = "#{BASE_URL}/search/authors.json?q=#{query}"
      
      Rails.logger.info "Searching OpenLibrary for author: #{name}"
      
      response = fetch_json(url)
      return nil unless response && response['docs'].present?

      # Find best match
      author = find_best_match(response['docs'], name)
      return nil unless author

      Rails.logger.debug "Found author in search results: #{author.inspect}"

      {
        name: author['name'],
        birth_date: parse_date(author['birth_date']),
        death_date: parse_date(author['death_date']),
        open_library_id: author['key']&.split('/')&.last,
        raw_data: author  # Include all the raw data
      }
    rescue => e
      Rails.logger.error "OpenLibrary API error: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      nil
    end

    def lookup_book(title, author = nil)
      query = build_book_query(title, author)
      url = "#{BASE_URL}/search.json?#{query}"
      
      Rails.logger.info "Searching OpenLibrary for book: #{title} by #{author}"
      
      response = fetch_json(url)
      return nil unless response && response['docs'].present?

      # Find best match
      book = find_best_book_match(response['docs'], title, author)
      return nil unless book

      Rails.logger.debug "Found book in search results: #{book.inspect}"

      {
        title: book['title'],
        author_names: book['author_name'],
        first_publish_year: book['first_publish_year'],
        open_library_id: extract_book_id(book),
        isbn: book['isbn']&.first,
        raw_data: book  # Include all the raw data
      }
    rescue => e
      Rails.logger.error "OpenLibrary API error: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      nil
    end

    private

    def fetch_json(url)
      uri = URI(url)
      Rails.logger.debug "Fetching URL: #{url}"
      
      response = Net::HTTP.get_response(uri)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "HTTP request failed: #{response.code} - #{response.body}"
        return nil
      end
      
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "Error fetching JSON: #{e.message}"
      nil
    end

    def find_best_match(docs, search_name)
      search_name = search_name.downcase
      Rails.logger.debug "Searching through #{docs.length} results for: #{search_name}"
      
      docs.find do |doc|
        match = doc['name']&.downcase == search_name ||
                doc['alternate_names']&.any? { |name| name.downcase == search_name }
        Rails.logger.debug "Checking #{doc['name']}: #{match ? 'matched' : 'no match'}" if doc['name']
        match
      end
    end

    def parse_date(date_str)
      return nil if date_str.blank?
      Date.parse(date_str)
    rescue
      nil
    end

    def build_book_query(title, author)
      query_parts = ["title=#{URI.encode_www_form_component(title)}"]
      query_parts << "author=#{URI.encode_www_form_component(author)}" if author.present?
      query_parts.join('&')
    end

    def find_best_book_match(docs, search_title, search_author)
      search_title = search_title.downcase
      search_author = search_author&.downcase
      
      Rails.logger.debug "Searching through #{docs.length} results for: #{search_title}"
      
      docs.find do |doc|
        title_match = doc['title']&.downcase == search_title
        
        author_match = if search_author && doc['author_name']
          doc['author_name'].any? { |name| name.downcase.include?(search_author) }
        else
          true # If no author specified, don't filter by author
        end

        Rails.logger.debug "Checking #{doc['title']}: title match: #{title_match}, author match: #{author_match}"
        
        title_match && author_match
      end
    end

    def extract_book_id(book)
      # Try different possible locations of the book ID
      return book['key']&.split('/')&.last if book['key']
      return book['edition_key']&.first if book['edition_key']&.any?
      return book['seed']&.first&.split('/')&.last if book['seed']&.any?
      nil
    end
  end
end 