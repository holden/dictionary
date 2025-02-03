class CreateExpressionTopics < ActiveRecord::Migration[8.0]
  def change
    # Create the join table
    create_table :expression_topics do |t|
      t.references :expression, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.timestamps
    end

    # Add unique index to prevent duplicate associations
    add_index :expression_topics, [:expression_id, :topic_id], unique: true

    # Copy existing relationships
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO expression_topics (expression_id, topic_id, created_at, updated_at)
          SELECT id, topic_id, created_at, updated_at
          FROM expressions
        SQL
      end
    end

    # Remove topic_id from expressions
    remove_reference :expressions, :topic, foreign_key: true
  end

  def down
    add_reference :expressions, :topic, foreign_key: true

    reversible do |dir|
      dir.down do
        execute <<-SQL
          UPDATE expressions
          SET topic_id = (
            SELECT topic_id 
            FROM expression_topics 
            WHERE expression_topics.expression_id = expressions.id 
            LIMIT 1
          )
        SQL
      end
    end

    drop_table :expression_topics
  end
end 