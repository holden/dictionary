class CreateMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :media do |t|
      t.string :title, null: false
      t.string :type, null: false  # STI type (Movie, TVShow, Photo, Art)
      t.jsonb :metadata, default: {}  # Flexible storage for API-specific data
      
      # External service identifiers - all nullable
      t.string :tmdb_id     # TMDB identifier for Movies and TV Shows
      t.string :unsplash_id # Unsplash identifier for Photos
      t.string :artsy_id    # Artsy identifier for Art

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        # Add indexes
        add_index :media, :type
        add_index :media, :title
        add_index :media, :tmdb_id, unique: true, where: "tmdb_id IS NOT NULL"
        add_index :media, :unsplash_id, unique: true, where: "unsplash_id IS NOT NULL"
        add_index :media, :artsy_id, unique: true, where: "artsy_id IS NOT NULL"
      end

      dir.down do
        # Remove indexes in reverse order
        remove_index :media, :artsy_id if index_exists?(:media, :artsy_id)
        remove_index :media, :unsplash_id if index_exists?(:media, :unsplash_id)
        remove_index :media, :tmdb_id if index_exists?(:media, :tmdb_id)
        remove_index :media, :title if index_exists?(:media, :title)
        remove_index :media, :type if index_exists?(:media, :type)
      end
    end
  end
end 