class ConceptNetLookupJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(topic_id)
    topic = Topic.find(topic_id)
    topic.refresh_conceptnet_data!
    topic.update_conceptnet_relationships!
  end
end 