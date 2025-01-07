class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.references :author, foreign_key: { to_table: :people }
      t.string :open_library_id
      t.date :published_date

      t.timestamps
      
      t.index :open_library_id, unique: true, where: "open_library_id IS NOT NULL"
    end
  end
end 