class WikiQuotesService
  include HTTParty
  base_uri 'https://en.wikiquotes.org/w/api.php'
  
  # Fix SSL verification options
  ssl_version :TLSv1_2
  default_options.update(verify: false)  # For development only - handle differently in production
  
  def initialize(topic_title)
    @topic_title = topic_title
    Rails.logger.debug "WikiQuotes: Initializing service for topic '#{topic_title}'"
  end

  def fetch_quotes(limit = 3)
    Rails.logger.debug "WikiQuotes: Fetching quotes for '#{@topic_title}'"
    search_result = search_page
    
    Rails.logger.debug "WikiQuotes: Search result: #{search_result.inspect}"
    return [] unless search_result['query']&.dig('search')&.first

    page_id = search_result['query']['search'].first['pageid']
    Rails.logger.debug "WikiQuotes: Found page ID: #{page_id}"
    
    fetch_page_quotes(page_id, limit)
  rescue StandardError => e
    Rails.logger.error "WikiQuotes Error: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
    []
  end

  def debug_info
    {
      topic: @topic_title,
      search_result: search_page,
      timestamp: Time.current
    }
  rescue StandardError => e
    {
      topic: @topic_title,
      error: e.message,
      timestamp: Time.current
    }
  end

  private

  def search_page
    query_params = {
      action: 'query',
      list: 'search',
      srsearch: @topic_title,
      format: 'json',
      srprop: 'snippet'
    }
    Rails.logger.debug "WikiQuotes: Searching with params: #{query_params.inspect}"
    
    self.class.get('', query: query_params, verify: false)  # Add verify: false to individual requests
  end

  def fetch_page_quotes(page_id, limit)
    query_params = {
      action: 'parse',
      pageid: page_id,
      format: 'json',
      prop: 'text'
    }
    Rails.logger.debug "WikiQuotes: Fetching page with params: #{query_params.inspect}"
    
    response = self.class.get('', query: query_params, verify: false)  # Add verify: false to individual requests
    Rails.logger.debug "WikiQuotes: Page response: #{response.inspect}"

    parse_quotes_from_html(response.dig('parse', 'text', '*'), limit)
  end

  def parse_quotes_from_html(html_content, limit)
    return [] unless html_content

    doc = Nokogiri::HTML(html_content)
    quotes = doc.css('ul li').map(&:text)
      .reject { |quote| quote.include?('citation needed') }
      .map { |quote| sanitize_quote(quote) }
      .reject(&:blank?)
      .first(limit)

    Rails.logger.debug "WikiQuotes: Parsed #{quotes.length} quotes: #{quotes.inspect}"
    quotes
  end

  def sanitize_quote(quote)
    sanitized = quote.gsub(/\[edit\]|\n/, '').strip
    Rails.logger.debug "WikiQuotes: Sanitized quote '#{quote}' to '#{sanitized}'"
    sanitized
  end
end 