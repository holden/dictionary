namespace :dictionary do
  desc "Clean up duplicate topic relationships"
  task cleanup_relationships: :environment do
    puts "Starting relationship cleanup..."
    
    ActiveRecord::Base.transaction do
      # Use raw SQL to get unique relationships
      unique_relationships_sql = <<-SQL
        SELECT DISTINCT ON (topic_id, related_topic_id) 
          id, topic_id, related_topic_id, relationship_type, weight
        FROM topic_relationships
        ORDER BY topic_id, related_topic_id, created_at DESC
      SQL
      
      unique_relationships = ActiveRecord::Base.connection.execute(unique_relationships_sql)
      
      # Delete all existing relationships
      TopicRelationship.delete_all
      
      # Recreate only the unique relationships
      unique_relationships.each do |rel|
        ActiveRecord::Base.connection.execute(<<-SQL)
          INSERT INTO topic_relationships 
            (topic_id, related_topic_id, relationship_type, weight, created_at, updated_at)
          VALUES 
            (#{rel['topic_id']}, 
             #{rel['related_topic_id']}, 
             '#{rel['relationship_type']}', 
             #{rel['weight'] || 'NULL'}, 
             NOW(), 
             NOW())
        SQL
      end
    end
    
    puts "Relationship cleanup completed!"
    puts "Total relationships: #{TopicRelationship.count}"
  end
end 