class AddOpenlibraryIdToTopics < ActiveRecord::Migration[7.1]
  def change
    add_column :topics, :openlibrary_id, :string
    add_index :topics, :openlibrary_id
  end
end 