class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.string :type, null: false, index: true
      t.string :title, null: false, index: { unique: true }
      t.integer :part_of_speech, null: false, default: 0, index: true
      t.string :conceptnet_id, index: { unique: true, where: "conceptnet_id IS NOT NULL" }

      t.timestamps

      # Update the check constraint to use 'Thing' instead of 'Object'
      t.check_constraint "type IN ('Person', 'Place', 'Concept', 'Thing', 'Event', 'Action', 'Other')", 
                        name: 'valid_topic_type'
                        
      t.check_constraint 'part_of_speech >= 0 AND part_of_speech <= 4',
                        name: 'valid_part_of_speech'
    end

    # Add a GiST index for pattern matching on title
    execute <<-SQL
      CREATE INDEX index_topics_on_title_pattern ON topics USING gin (title gin_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_topics_on_title_pattern"
    drop_table :topics
  end
end
