class CreateMediaPeople < ActiveRecord::Migration[7.1]
  def change
    create_table :media_people do |t|
      t.references :media, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role  # Optional: specifies relationship (Actor, Artist, etc.)
      t.timestamps
    end

    add_index :media_people, [:media_id, :person_id], unique: true
  end
end 