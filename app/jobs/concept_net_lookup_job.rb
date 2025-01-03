class ConceptNetLookupJob < ApplicationJob
  queue_as :default

  def perform(topic_id)
    topic = Topic.find(topic_id)
    
    # Skip ConceptNet lookup for authors
    return if topic.type == "Person"

    # Only proceed if we don't have relationships yet
    return if topic.topic_relationships.exists?

    topic.update_conceptnet_relationships!
  end
end 