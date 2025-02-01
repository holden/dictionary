class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      # Polymorphic associations for what's being voted on
      t.references :votable, polymorphic: true, null: false
      
      # Polymorphic associations for who/what is voting (User or Bot)
      t.references :voter, polymorphic: true, null: false
      
      # Vote details
      t.boolean :vote_flag, null: false  # true for upvote, false for downvote
      t.float :vote_weight, default: 1.0 # allows for weighted voting (esp. for bots)
      
      # Bot-specific voting metadata
      t.jsonb :metadata, default: {}, null: false  # stores bot's decision process, confidence level, etc.
      
      t.timestamps
    end

    # Indexes for efficient querying
    add_index :votes, [:voter_id, :voter_type]
    add_index :votes, [:votable_id, :votable_type]
    add_index :votes, :metadata, using: :gin
    
    # Ensure a voter can only vote once on a specific item
    add_index :votes, [:voter_id, :voter_type, :votable_id, :votable_type], 
      unique: true, 
      name: 'index_votes_uniqueness'
  end
end 