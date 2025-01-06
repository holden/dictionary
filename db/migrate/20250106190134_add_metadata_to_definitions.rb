class AddMetadataToDefinitions < ActiveRecord::Migration[8.0]
  def change
    add_column :definitions, :metadata, :jsonb, null: false, default: {}
    add_index :definitions, :metadata, using: :gin
  end
end 