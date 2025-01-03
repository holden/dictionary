class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.references :topic, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :topics }, null: true
      t.string :attribution_text # Raw text of who said it, used when no author record exists
      t.text :context # Additional context about the quote
      t.string :source_url # URL where the quote was found
      t.date :said_on # When the quote was said (if known)
      
      # Wikiquote specific fields
      t.string :section_title # The section in Wikiquote where this quote appears
      t.string :wikiquote_section_id # Combination of page title and section anchor
      t.text :original_text # Original language text if available
      t.string :original_language # Language code of original text
      t.text :citation # Formal citation if provided
      t.boolean :disputed, default: false # Some quotes are marked as disputed
      t.boolean :misattributed, default: false # Some quotes are marked as misattributed
      
      t.jsonb :metadata, default: {}, null: false # For any additional data

      t.timestamps
    end

    add_index :quotes, :attribution_text
    add_index :quotes, [:topic_id, :created_at]
    add_index :quotes, :wikiquote_section_id # Help prevent duplicates
    add_index :quotes, :metadata, using: :gin
  end
end 