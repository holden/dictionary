class Lyric < Expression
  validates :source_title, presence: true  # Require song/album title for lyrics
  
  def self.model_name
    Expression.model_name
  end
  
  def display_text
    text = super
    text += " (from #{source_title})" if source_title.present?
    text
  end
end 