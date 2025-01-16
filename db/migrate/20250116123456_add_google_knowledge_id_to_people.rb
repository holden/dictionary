class AddGoogleKnowledgeIdToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :google_knowledge_id, :string
    add_index :people, :google_knowledge_id, unique: true
  end
end 