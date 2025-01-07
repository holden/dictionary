class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    # First remove any existing foreign keys if they exist
    remove_foreign_key :quotes, column: :author_id if foreign_key_exists?(:quotes, :author_id)
    remove_foreign_key :books, column: :author_id if foreign_key_exists?(:books, :author_id)

    create_table :people do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :open_library_id
      t.date :birth_date
      t.date :death_date
      t.jsonb :metadata, null: false, default: {}
      t.tsvector :tsv

      t.timestamps
      
      t.index :title, unique: true
      t.index :slug, unique: true
      t.index :open_library_id, unique: true, where: "open_library_id IS NOT NULL"
      t.index :tsv, using: :gin
      t.index :metadata, using: :gin
    end

    # Add new foreign keys
    add_foreign_key :quotes, :people, column: :author_id
    add_foreign_key :books, :people, column: :author_id
    
    # Add indexes if they don't exist
    add_index :quotes, :author_id unless index_exists?(:quotes, :author_id)
    add_index :books, :author_id unless index_exists?(:books, :author_id)
  end

  private

  def foreign_key_exists?(from_table, column)
    foreign_keys(from_table).any? { |fk| fk.column == column.to_s }
  end
end 