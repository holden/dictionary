class ConvertQuotesToExpressions < ActiveRecord::Migration[8.0]
  def up
    # Rename the table
    rename_table :quotes, :expressions
    
    # Add type column for STI
    add_column :expressions, :type, :string
    
    # Add additional fields for lyrics/poems
    add_column :expressions, :year_written, :integer
    add_column :expressions, :source_title, :string  # e.g. song/album name, book title
    
    # Update existing records to be of type Quote
    execute "UPDATE expressions SET type = 'Quote'"
    
    # Add index for STI
    add_index :expressions, :type
  end

  def down
    remove_index :expressions, :type
    remove_column :expressions, :type
    remove_column :expressions, :year_written
    remove_column :expressions, :source_title
    rename_table :expressions, :quotes
  end
end 