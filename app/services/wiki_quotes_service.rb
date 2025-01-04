class WikiQuotesService
  include HTTParty
  base_uri 'https://en.wikiquote.org/w/api.php'
  
  class Error < StandardError; end
  
  # Fix SSL verification options
  ssl_version :TLSv1_2
  default_options.update(verify: false)  # For development only
  
  Result = Struct.new(
    :content,
    :author,
    :citation,
    :source_url,
    :metadata,
    :original_text,
    :attribution_text,
    :context,
    :section_title,
    :wikiquote_section_id,
    :disputed,
    :misattributed,
    :page_title,
    :search_query,
    :search_author,
    :search_section,
    keyword_init: true
  )

  def initialize(topic_title)
    @topic_title = topic_title
  end

  def fetch_quotes(limit = 3)
    Rails.cache.fetch("wikiquotes/#{@topic_title}", expires_in: 1.hour) do
      self.class.search(q: @topic_title, limit: limit)
    end
  rescue StandardError => e
    Rails.logger.error "WikiQuotes Error: #{e.message}"
    []
  end

  class << self
    def search(params)
      Rails.logger.info "Searching Wikiquotes with params: #{params.inspect}"
      
      # First search for pages based on author or term
      pages = if params[:author].present?
        fetch_author_pages(params[:author])
      else
        fetch_pages(params[:q])
      end
      
      Rails.logger.info "Found #{pages.size} pages"
      
      # Then get quotes from each page with filters
      results = pages.flat_map do |page|
        fetch_quotes_from_page(page, params)
      end

      Rails.logger.info "Found #{results.size} quotes"
      results
    rescue StandardError => e
      Rails.logger.error "Wikiquotes API error: #{e.message}"
      raise Error, "Wikiquotes API error: #{e.message}"
    end

    private

    def fetch_quotes_from_page(page, params)
      response = get('', query: {
        action: 'parse',
        page: page['title'],
        format: 'json',
        prop: 'sections|text',
        utf8: 1
      })

      handle_response(response) do |data|
        parse_quotes_from_html(
          data.dig('parse', 'text', '*'),
          page['title'],
          params
        )
      end
    end

    def fetch_author_pages(author)
      response = get('', query: {
        action: 'query',
        list: 'search',
        srnamespace: '0',
        srsearch: author,
        srlimit: 10,
        format: 'json',
        utf8: 1,
        language: 'en'
      })

      handle_response(response) do |data|
        data.dig('query', 'search') || []
      end
    end

    def fetch_pages(term)
      return [] if term.blank?
      
      response = get('', query: {
        action: 'query',
        list: 'search',
        srsearch: term,
        srlimit: 10,
        format: 'json',
        utf8: 1
      })

      handle_response(response) do |data|
        data.dig('query', 'search') || []
      end
    end

    def parse_quotes_from_html(html, page_title, params)
      return [] unless html

      doc = Nokogiri::HTML(html)
      quotes = []
      
      # Get all sections first
      sections = doc.css('.mw-parser-output > h2').map do |h2|
        {
          title: h2.css('.mw-headline').text,
          element: h2
        }
      end

      # Look for quotes in various formats
      doc.css('.mw-parser-output > ul li, .mw-parser-output > dl dd').each do |node|
        text = node.text.strip
        next if text.empty?
        
        if params[:q].present?
          next unless text.downcase.include?(params[:q].downcase)
        end
        
        current_section = find_current_section(sections, node)
        citation_parts, context, extracted_author = extract_metadata(node, current_section)
        speaker, content = extract_content_and_speaker(text)

        # Use the citation or extracted author for attribution
        author = if citation_parts.first =~ /^([^,]+)/
          $1.strip  # Extract author from citation
        elsif extracted_author
          extracted_author
        elsif params[:author].present?
          params[:author].titleize
        else
          page_title
        end

        quotes << Result.new(
          content: content,
          author: author,
          citation: citation_parts.compact.uniq.join(' - '),
          source_url: "https://en.wikiquote.org/wiki/#{CGI.escape(page_title)}",
          original_text: node.inner_html,
          attribution_text: speaker,
          context: context.compact.join(' - '),
          section_title: current_section&.dig(:title),
          wikiquote_section_id: current_section&.dig(:title)&.parameterize,
          disputed: current_section&.dig(:title)&.downcase == 'disputed',
          misattributed: current_section&.dig(:title)&.downcase == 'misattributed',
          page_title: page_title,
          search_query: params[:q],
          search_author: params[:author],
          search_section: params[:namespace],
          metadata: {
            wikiquote: {
              page_title: page_title,
              section: current_section&.dig(:title),
              disputed: current_section&.dig(:title)&.downcase == 'disputed',
              misattributed: current_section&.dig(:title)&.downcase == 'misattributed'
            }
          }
        )
      end

      quotes
    end

    def find_current_section(sections, node)
      sections.reverse.find do |section|
        node.path.match(/#{section[:element].path}\/following::/)
      end
    end

    def extract_metadata(node, current_section)
      citation_parts = []
      context = []
      author = nil
      
      # Try to extract author and citation from list items
      if node.css('ul li').any?
        citation_text = node.css('ul li').map(&:text).join(', ')
        citation_parts << citation_text
        
        # Try to extract author from citation
        if citation_text =~ /^([^,]+?)(?:,|\s+\()/
          author = $1.strip
        end
      end
      
      # Look for links that might indicate author
      node.css('a').each do |link|
        if link['title']&.present? && !link['href']&.include?('wikipedia.org')
          possible_author = link.text.strip
          # Less strict author matching - just check for reasonable length
          author ||= possible_author if possible_author.length < 50 && possible_author.match?(/^[A-Z]/)
        end
      end

      # Extract date if present
      if node.text =~ /\((\d{1,2}\s+[A-Za-z]+\s+\d{4})\)/
        context << $1
      end

      context << current_section[:title] if current_section

      [citation_parts, context, author]
    end

    def extract_content_and_speaker(text)
      if text =~ /^([^:]+?):\s*(.+)/
        [$1.strip, $2.strip]
      elsif text =~ /—\s*([^,\n]+)/
        [$1.strip, text.sub(/—\s*[^,\n]+/, '').strip]
      else
        [nil, text]
      end
    end

    def extract_author_from_citation(citation)
      return nil unless citation
      
      # Match patterns like "Author Name, Title (Year)" or "Author Name (Year)"
      if citation =~ /^([^,\(]+)(?:,|\s+\()/
        $1.strip
      else
        nil
      end
    end

    def handle_response(response)
      unless response.success?
        raise Error, "API request failed: #{response.code} - #{response.message}"
      end

      data = JSON.parse(response.body)
      if data['error']
        raise Error, "API error: #{data['error']['info']}"
      end

      yield(data)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    end
  end
end 