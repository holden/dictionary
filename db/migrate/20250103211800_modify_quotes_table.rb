class ModifyQuotesTable < ActiveRecord::Migration[7.1]
  def change
    change_table :quotes do |t|
      # Add user reference
      t.references :user, null: false, foreign_key: true

      # Remove unused columns
      t.remove :context
      t.remove :said_on
      t.remove :section_title
      t.remove :wikiquote_section_id
    end
  end
end 