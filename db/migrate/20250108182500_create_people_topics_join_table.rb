class CreatePeopleTopicsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_table :people_topics, id: false do |t|
      t.belongs_to :person
      t.belongs_to :topic
      t.timestamps
      t.index [:person_id, :topic_id], unique: true
    end
  end
end 