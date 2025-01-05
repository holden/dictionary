class CreateTopicRelationshipsJob < ApplicationJob
  queue_as :default
  
  def perform(topic_id)
    topic = Topic.find_by(id: topic_id)
    return unless topic

    Rails.logger.info "Starting relationship creation for Topic ##{topic_id} (#{topic.title})"
    
    begin
      topic.update_relationships!
    rescue StandardError => e
      Rails.logger.error "Failed to create relationships for Topic ##{topic_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e # Re-raise to trigger job retry
    end
  end

  retry_on StandardError, wait: :exponentially_longer, attempts: 3
end 