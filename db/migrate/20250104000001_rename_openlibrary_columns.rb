class RenameOpenlibraryColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :topics, :openlibrary_id, :open_library_id
    rename_column :books, :openlibrary_id, :open_library_id
  end
end 