class PoetryDbService
  include HTTParty
  base_uri 'https://poetrydb.org'
  
  def self.search_by_author(author)
    Rails.logger.info "Searching PoetryDB for author: #{author}"
    response = get("/author/#{URI.encode_www_form_component(author)}")
    Rails.logger.info "PoetryDB response status: #{response.code}"
    Rails.logger.info "PoetryDB response body: #{response.body[0..200]}..."
    
    return [] if response.code == 404
    return [] unless response.success?
    
    # Handle both array and single object responses
    poems = response.parsed_response
    poems = [poems] unless poems.is_a?(Array)
    
    poems.map do |poem|
      {
        content: poem['lines'].join("\n"),
        attribution_text: poem['author'],
        source_title: poem['title'],
        year_written: nil,
        metadata: {
          poetrydb: {
            lines: poem['lines'],
            linecount: poem['linecount']
          }
        }
      }
    end
  rescue => e
    Rails.logger.error "PoetryDB API error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end

  def self.search_by_title(title)
    Rails.logger.info "Searching PoetryDB for title: #{title}"
    response = get("/title/#{URI.encode_www_form_component(title)}")
    Rails.logger.info "PoetryDB response status: #{response.code}"
    Rails.logger.info "PoetryDB response body: #{response.body[0..200]}..."
    
    return [] if response.code == 404
    return [] unless response.success?
    
    # Handle both array and single object responses
    poems = response.parsed_response
    poems = [poems] unless poems.is_a?(Array)
    
    poems.map do |poem|
      {
        content: poem['lines'].join("\n"),
        attribution_text: poem['author'],
        source_title: poem['title'],
        year_written: nil,
        metadata: {
          poetrydb: {
            lines: poem['lines'],
            linecount: poem['linecount']
          }
        }
      }
    end
  rescue => e
    Rails.logger.error "PoetryDB API error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end
end 