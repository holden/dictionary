class CreateMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :media do |t|
      t.string :title, null: false
      t.string :type, null: false  # STI type (Movie, TVShow, Art)
      t.jsonb :metadata, default: {}  # Flexible storage for API-specific data
      t.string :tmdb_id  # TMDb identifier
      t.string :artsy_id  # Artsy identifier
      t.string :wikipedia_id  # Wikipedia identifier
      t.timestamps
    end

    add_index :media, :type
    add_index :media, :title
    add_index :media, :tmdb_id, unique: true
    add_index :media, :artsy_id, unique: true
    add_index :media, :wikipedia_id, unique: true
  end
end 