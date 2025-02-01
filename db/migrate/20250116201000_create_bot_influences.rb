class CreateBotInfluences < ActiveRecord::Migration[8.0]
  def change
    create_table :bot_influences do |t|
      t.references :bot, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.float :influence_weight, null: false, default: 1.0
      t.text :description
      t.jsonb :metadata, default: {}, null: false
      t.timestamps

      # Ensure a person can only influence a bot once
      t.index [:bot_id, :person_id], unique: true
      t.index :metadata, using: :gin
    end
  end
end 