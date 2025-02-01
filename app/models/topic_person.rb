class TopicPerson < ApplicationRecord
  self.table_name = 'people_topics'
  
  belongs_to :topic
  belongs_to :person
  
  # Make the relationship votable
  has_many :votes, as: :votable, dependent: :destroy

  # Scopes for vote tallying
  scope :with_vote_counts, -> {
    select("people_topics.*, 
            SUM(CASE WHEN votes.vote_flag THEN votes.vote_weight ELSE 0 END) as upvotes,
            SUM(CASE WHEN NOT votes.vote_flag THEN votes.vote_weight ELSE 0 END) as downvotes")
      .left_joins(:votes)
      .group('people_topics.person_id, people_topics.topic_id')
  }

  def score
    votes.sum('CASE WHEN vote_flag THEN vote_weight ELSE -vote_weight END')
  end
end 