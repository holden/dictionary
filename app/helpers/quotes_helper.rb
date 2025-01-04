module QuotesHelper
  def parse_quote(quote)
    if quote.respond_to?(:content)
      {
        content: quote.content,
        attribution: quote.author,
        source: quote.citation
      }
    else
      # For legacy string quotes
      parts = quote.to_s.split(/(?:—|,)\s*(?=[A-Z])/)
      if parts.size > 1
        {
          content: parts[0].strip,
          attribution: parts[1].strip,
          source: nil
        }
      else
        {
          content: quote.to_s,
          attribution: nil,
          source: nil
        }
      end
    end
  end
end 