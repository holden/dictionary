# rails generate migration AddSearchVectorToTopics
class AddSearchVectorToTopics < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE topics ADD COLUMN tsv tsvector;
      CREATE INDEX topics_tsv_idx ON topics USING gin(tsv);
      
      -- Create a trigger to automatically update tsv column when title changes
      CREATE TRIGGER topics_tsv_update BEFORE INSERT OR UPDATE
      ON topics FOR EACH ROW EXECUTE FUNCTION
      tsvector_update_trigger(tsv, 'pg_catalog.english', title);
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS topics_tsv_update ON topics;
      DROP INDEX IF EXISTS topics_tsv_idx;
      ALTER TABLE topics DROP COLUMN IF EXISTS tsv;
    SQL
  end
end