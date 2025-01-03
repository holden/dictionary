class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.references :topic, null: false, foreign_key: true
      t.text :content
      t.string :author
      t.string :source_url

      t.timestamps
    end
  end
end 