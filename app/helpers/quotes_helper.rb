module QuotesHelper
  def parse_quote(quote)
    # Split on em dash or comma followed by author name
    parts = quote.split(/(?:—|,)\s*(?=[A-Z])/)
    
    if parts.size > 1
      content = parts[0].strip
      attribution_parts = parts[1].split(/[(),]/).map(&:strip)
      
      {
        content: content,
        attribution: attribution_parts[0],
        source: attribution_parts[1..-1].reject(&:blank?).join(', ')
      }
    else
      { content: quote, attribution: nil, source: nil }
    end
  end
end 