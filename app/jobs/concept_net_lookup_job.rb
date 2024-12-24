class ConceptNetLookupJob < ApplicationJob
  queue_as :default
  retry_on StandardError, 
           attempts: 3, 
           wait: -> (executions) { executions * 2 }  # 2, 4, 6 seconds

  def perform(topic_id)
    topic = Topic.find(topic_id)
    topic.refresh_conceptnet_data!
    topic.update_conceptnet_relationships!
  end
end 