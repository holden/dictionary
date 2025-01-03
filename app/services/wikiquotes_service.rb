class WikiquotesService
  class Error < StandardError; end
  BASE_URL = "https://en.wikiquote.org/w/api.php"

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
        fetch_quotes(page, params)
      end

      Rails.logger.info "Found #{results.size} quotes"
      results
    rescue StandardError => e
      Rails.logger.error "Wikiquotes API error: #{e.message}"
      raise Error, "Wikiquotes API error: #{e.message}"
    end

    private

    def fetch_author_pages(author)
      response = HTTParty.get(BASE_URL, query: {
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
      
      response = HTTParty.get(BASE_URL, query: {
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

    def fetch_quotes(page, params)
      response = HTTParty.get(BASE_URL, query: {
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
        next if params[:q].present? && !text.downcase.include?(params[:q].downcase)
        
        # Skip non-English quotes
        next if text.match?(/[^\x00-\x7F]/) # Skip if contains non-ASCII characters

        # Find the current section
        current_section = sections.reverse.find do |section|
          node.path.match(/#{section[:element].path}\/following::/)
        end

        # Extract citation and context
        citation_parts = []
        context = []
        
        # Try to extract citation from the node's content
        if node.css('ul li').any?
          citation_parts << node.css('ul li').map(&:text).join(', ')
        end
        
        # Look for links that might indicate sources
        node.css('a').each do |link|
          if link['href']&.include?('wikipedia.org')
            citation_parts << link.text
          end
        end

        # Extract date if present
        if text =~ /\((\d{1,2}\s+[A-Za-z]+\s+\d{4})\)/
          context << $1
        end

        # Add section as context if available
        context << current_section[:title] if current_section

        # Extract speaker/attribution
        speaker = nil
        content = text
        
        # Try different patterns for attribution
        if text =~ /^([^:]+?):\s*(.+)/
          speaker = $1.strip
          content = $2.strip
        elsif text =~ /—\s*([^,\n]+)/
          speaker = $1.strip
        end

        quotes << {
          content: content,
          source_url: "https://en.wikiquote.org/wiki/#{CGI.escape(page_title)}##{CGI.escape(current_section ? current_section[:title] : '')}",
          section: current_section&.dig(:title),
          original_text: node.inner_html,
          author: params[:author],
          context: context.compact.join(' - '),
          citation: citation_parts.compact.uniq.join(' - '),
          attribution_text: speaker,
          section_title: current_section&.dig(:title),
          wikiquote_section_id: current_section&.dig(:title)&.parameterize,
          disputed: current_section&.dig(:title)&.downcase == 'disputed',
          misattributed: current_section&.dig(:title)&.downcase == 'misattributed',
          page_title: page_title,
          search_query: params[:q],
          search_author: params[:author],
          search_section: params[:namespace]
        }
      end

      quotes
    end

    def extract_author(node)
      # Look for attribution patterns
      if node.text =~ /—\s*([^,\n]+)/ || 
         node.text =~ /~\s*([^,\n]+)/ ||
         node.text =~ /\[\s*([^\]]+)\s*\]/
        $1.strip
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