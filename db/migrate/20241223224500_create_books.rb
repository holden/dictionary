class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.references :author, foreign_key: { to_table: :topics }
      t.string :openlibrary_id
      t.date :published_date
      t.timestamps

      t.index :openlibrary_id, unique: true, where: "openlibrary_id IS NOT NULL"
    end
  end
end 