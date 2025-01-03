class AddCascadeDeleteToQuotes < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing foreign key
    remove_foreign_key :quotes, :topics, column: :author_id

    # Add it back with ON DELETE CASCADE
    add_foreign_key :quotes, :topics, 
      column: :author_id, 
      on_delete: :cascade,
      validate: false  # Skip validation for speed

    # Validate the constraint
    validate_foreign_key :quotes, :topics, column: :author_id
  end

  def down
    remove_foreign_key :quotes, :topics, column: :author_id
    add_foreign_key :quotes, :topics, column: :author_id
  end
end
