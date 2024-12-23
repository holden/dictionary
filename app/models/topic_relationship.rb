class TopicRelationship < ApplicationRecord
  belongs_to :topic
  belongs_to :related_topic, class_name: 'Topic'

  validates :relationship_type, presence: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :topic_id, uniqueness: { scope: [:related_topic_id, :relationship_type] }
end 