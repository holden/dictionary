class UpdateTopicTypeConstraint < ActiveRecord::Migration[7.1]
  def up
    remove_check_constraint :topics, name: 'valid_topic_type'
    add_check_constraint :topics, 
      "type IN ('Person', 'Place', 'Concept', 'Thing', 'Event', 'Action', 'Other')",
      name: 'valid_topic_type'
  end

  def down
    remove_check_constraint :topics, name: 'valid_topic_type'
    add_check_constraint :topics,
      "type IN ('Person', 'Place', 'Concept', 'Object', 'Event', 'Action', 'Other')",
      name: 'valid_topic_type'
  end
end 