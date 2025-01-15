class UpdateMediaIdentifiers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :media, :tmdb_id, true
    add_column :media, :unsplash_id, :string
    add_index :media, :unsplash_id, unique: true
  end
end 