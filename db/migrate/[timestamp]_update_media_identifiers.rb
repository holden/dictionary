class UpdateMediaIdentifiers < ActiveRecord::Migration[7.1]
  def change
    # First ensure tmdb_id is nullable
    change_column_null :media, :tmdb_id, true

    # Then add unsplash_id if it doesn't exist
    unless column_exists?(:media, :unsplash_id)
      add_column :media, :unsplash_id, :string
      add_index :media, :unsplash_id, unique: true
    end

    # Add index on tmdb_id if it doesn't exist
    unless index_exists?(:media, :tmdb_id)
      add_index :media, :tmdb_id, unique: true
    end
  end
end 