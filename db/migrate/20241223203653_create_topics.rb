class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.string :type, null: false
      t.string :conceptnet_id
      t.timestamps

      t.index :title, unique: true
      t.index :type
      t.index :conceptnet_id, unique: true, where: "conceptnet_id IS NOT NULL"

      t.check_constraint "type IN ('Person', 'Place', 'Concept', 'Object', 'Event', 'Action', 'Other')", name: 'valid_type'
    end
  end
end
