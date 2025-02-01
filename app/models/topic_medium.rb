class TopicMedium < ApplicationRecord
  self.table_name = 'media_topics'
  
  belongs_to :topic
  belongs_to :media, class_name: 'Media'
  
  # Make the relationship votable
  has_many :votes, as: :votable, dependent: :destroy

  # Scopes for vote tallying
  scope :with_vote_counts, -> {
    select("media_topics.*, 
            SUM(CASE WHEN votes.vote_flag THEN votes.vote_weight ELSE 0 END) as upvotes,
            SUM(CASE WHEN NOT votes.vote_flag THEN votes.vote_weight ELSE 0 END) as downvotes")
      .left_joins(:votes)
      .group('media_topics.media_id, media_topics.topic_id')
  }

  def score
    votes.sum('CASE WHEN vote_flag THEN vote_weight ELSE -vote_weight END')
  end
end 