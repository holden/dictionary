class AddCoolDataToPerson < ActiveRecord::Migration[8.0]
  def change
    add_column :topics, :metadata, :jsonb, default: {}, null: false
    add_index :topics, :metadata, using: :gin  # Add GIN index for JSON querying
  end
end
