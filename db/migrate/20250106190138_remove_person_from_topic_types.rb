class RemovePersonFromTopicTypes < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE topics DROP CONSTRAINT valid_type;
      ALTER TABLE topics ADD CONSTRAINT valid_type 
        CHECK (type::text = ANY (ARRAY[
          'Place'::character varying, 
          'Concept'::character varying, 
          'Thing'::character varying, 
          'Event'::character varying, 
          'Action'::character varying, 
          'Other'::character varying
        ]::text[]));
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE topics DROP CONSTRAINT valid_type;
      ALTER TABLE topics ADD CONSTRAINT valid_type 
        CHECK (type::text = ANY (ARRAY[
          'Person'::character varying,
          'Place'::character varying, 
          'Concept'::character varying, 
          'Thing'::character varying, 
          'Event'::character varying, 
          'Action'::character varying, 
          'Other'::character varying
        ]::text[]));
    SQL
  end
end 