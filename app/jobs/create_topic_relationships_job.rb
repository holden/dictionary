class CreateTopicRelationshipsJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, 
           wait: ->(executions) { [2, 4, 8, 16, 32][executions - 1] || 32 },
           attempts: 5 do |job, error|
    Rails.logger.error "Failed to create relationships for Topic ##{job.arguments.first}: #{error.message}"
  end

  def perform(topic_id)
    topic = Topic.find(topic_id)
    Rails.logger.info "Starting relationship creation for Topic ##{topic_id} (#{topic.name})"
    topic.update_relationships!
  end
end 