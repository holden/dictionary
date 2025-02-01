class CreateBots < ActiveRecord::Migration[8.0]
  def change
    create_table :bots do |t|
      t.string :name
      t.text :personality
      t.string :base_model
      t.float :voter_weight
      t.text :curation_focus

      t.timestamps
    end
  end
end
