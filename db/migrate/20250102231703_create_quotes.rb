class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :author, null: true, foreign_key: { to_table: :topics }
      t.string :attribution_text # Raw text of who said it, used when no author record exists
      t.string :source_url
      t.text :original_text # Original language text if available
      t.string :original_language # Language code of original text
      t.text :citation # Formal citation if provided
      t.boolean :disputed, default: false # Some quotes are marked as disputed
      t.boolean :misattributed, default: false # Some quotes are marked as misattributed
      t.references :user, null: false, foreign_key: true
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end
  end
end 