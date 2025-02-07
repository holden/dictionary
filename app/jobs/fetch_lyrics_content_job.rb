class FetchLyricsContentJob < ApplicationJob
  queue_as :default
  
  def perform(lyric_id)
    lyric = Lyric.find_by(id: lyric_id)
    return unless lyric&.source_url&.present?

    Rails.logger.info "Fetching lyrics content for #{lyric.source_url}"
    
    begin
      genius_service = GeniusService.new
      if content = genius_service.fetch_lyrics(lyric.source_url)
        lyric.update!(content: content[:content])  # Use update! to ensure it saves
        Rails.logger.info "Successfully updated lyrics content for #{lyric.source_url}"
      end
    rescue => e
      Rails.logger.error "Error fetching lyrics: #{e.message}"
    end
  end
end 