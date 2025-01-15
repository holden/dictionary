class UpdateMediaIdentifiersAgain < ActiveRecord::Migration[7.1]
  def change
    # Ensure both identifier columns are nullable and have unique indexes
    change_column_null :media, :tmdb_id, true
    
    add_column :media, :unsplash_id, :string unless column_exists?(:media, :unsplash_id)
    
    add_index :media, :tmdb_id, unique: true unless index_exists?(:media, :tmdb_id)
    add_index :media, :unsplash_id, unique: true unless index_exists?(:media, :unsplash_id)
  end
end 