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
  end
end 