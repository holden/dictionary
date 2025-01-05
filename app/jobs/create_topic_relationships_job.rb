class CreateTopicRelationshipsJob < ApplicationJob
  queue_as :default
  
  def perform(topic_id)
    topic = Topic.find_by(id: topic_id)
    return unless topic
    
    topic.update_relationships!
  rescue StandardError => e
    Rails.logger.error "Failed to create relationships for topic #{topic_id}: #{e.message}"
  end
end 