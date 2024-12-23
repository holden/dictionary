class CreateTopicRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :topic_relationships do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :related_topic, null: false, foreign_key: { to_table: :topics }
      t.string :relationship_type, null: false
      t.float :weight

      t.timestamps

      t.index [:topic_id, :related_topic_id, :relationship_type], 
              unique: true, 
              name: 'index_topic_relationships_uniqueness'
    end
  end
end
