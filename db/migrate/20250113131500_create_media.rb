class CreateMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :media do |t|
      t.string :title, null: false
      t.string :type, null: false  # STI type (Movie, TVShow, Photo, Art)
      t.jsonb :metadata, default: {}  # Flexible storage for API-specific data
      
      # Source tracking
      t.string :source_id   # External ID from the source API
      t.string :source_type # Name of the source API (TMDB, Unsplash, Artsy, Giphy)

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        # Add indexes
        add_index :media, :type
        add_index :media, :title
        add_index :media, [:source_type, :source_id], unique: true
      end

      dir.down do
        # Remove indexes in reverse order
        remove_index :media, [:source_type, :source_id] if index_exists?(:media, [:source_type, :source_id])
        remove_index :media, :title if index_exists?(:media, :title)
        remove_index :media, :type if index_exists?(:media, :type)
      end
    end
  end
end 