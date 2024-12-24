class CreateWebsites < ActiveRecord::Migration[7.1]
  def change
    create_table :websites do |t|
      t.string :url, null: false
      t.string :title
      t.text :description
      t.timestamps

      t.index :url, unique: true
    end
  end
end 