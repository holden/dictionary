class CreateDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :definitions do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :author, polymorphic: true
      t.references :source, polymorphic: true
      t.timestamps

      t.index [:author_type, :author_id], name: 'idx_definitions_author'
      t.index [:source_type, :source_id], name: 'idx_definitions_source'
    end
  end
end 