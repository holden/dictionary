class UpdateBookAuthorForeignKey < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing foreign key to topics
    remove_foreign_key :books, column: :author_id
    
    # Add the new foreign key to people
    add_foreign_key :books, :people, column: :author_id
  end
end 