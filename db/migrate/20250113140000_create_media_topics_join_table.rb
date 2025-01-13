class CreateMediaTopicsJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_table :media_topics, id: false do |t|
      t.references :media
      t.references :topic
      t.timestamps
    end

    add_index :media_topics, [:media_id, :topic_id], unique: true
  end
end 