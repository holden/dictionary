class AddTmdbIdToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :tmdb_id, :integer
    add_column :people, :imdb_id, :string
    
    add_index :people, :tmdb_id, unique: true
    add_index :people, :imdb_id, unique: true
  end
end 