class Lyric < Expression
  has_rich_text :content
  
  validates :content, presence: true
  validates :source_url, uniqueness: { scope: :type, allow_nil: true }
  
  validates :source_title, presence: true  # Require song/album title for lyrics
  
  after_create :fetch_lyrics_content
  
  def self.model_name
    Expression.model_name
  end
  
  def display_text
    text = super
    text += " (from #{source_title})" if source_title.present?
    text
  end

  def fetch_lyrics_content
    return unless source_url.present? && source_url.include?('genius.com')
    
    Rails.logger.info "Fetching lyrics content for #{source_url}"
    content_data = LyricsScrapingService.fetch_content(source_url)
    
    if content_data&.dig(:content).present?
      update(
        content: content_data[:content],
        metadata: metadata.deep_merge(
          genius: {
            scraping: {
              extracted_at: content_data[:extracted_at]
            }
          }
        )
      )
      Rails.logger.info "Successfully updated lyrics content for #{source_url}"
    else
      Rails.logger.error "Failed to fetch lyrics content for #{source_url}"
    end
  rescue => e
    Rails.logger.error "Error fetching lyrics: #{e.message}"
  end

  def reload_lyrics!
    fetch_lyrics_content
  end

  # Class method to reload lyrics for multiple records
  def self.reload_missing_lyrics
    where("content IS NULL OR content = ''").find_each do |lyric|
      lyric.reload_lyrics!
    rescue => e
      Rails.logger.error "Failed to reload lyrics for ID #{lyric.id}: #{e.message}"
    end
  end
end 