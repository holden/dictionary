class Lyric < Expression
  belongs_to :author, class_name: 'Person', optional: true
  belongs_to :user
  has_many :topic_lyrics, dependent: :destroy
  has_many :topics, through: :topic_lyrics
  has_rich_text :content
  
  validates :source_url, uniqueness: { scope: :type, allow_nil: true }
  validates :source_title, presence: true
  
  after_create :schedule_lyrics_fetch
  
  def self.model_name
    Expression.model_name
  end
  
  def display_text
    text = super
    text += " (from #{source_title})" if source_title.present?
    text
  end

  private

  def schedule_lyrics_fetch
    return unless source_url.present?
    FetchLyricsContentJob.perform_later(id)
  end
end 