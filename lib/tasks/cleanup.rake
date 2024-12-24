namespace :dictionary do
  desc "Standardize titles and merge duplicate topics"
  task cleanup: :environment do
    puts "Starting title standardization..."
    
    ActiveRecord::Base.transaction do
      # First, drop the unique index
      ActiveRecord::Base.connection.execute(
        "DROP INDEX IF EXISTS index_topics_on_title;"
      )
      
      # Group topics by downcased title
      Topic.all.group_by { |t| t.title.downcase }.each do |downcased, topics|
        next if topics.length == 1 # Skip if no duplicates
        
        puts "Found #{topics.length} entries for '#{downcased}'"
        
        # Use the first topic as primary
        primary = topics.first
        
        # Update the primary title
        standardized_title = Topic::SPECIAL_CASES[downcased] || primary.title.titleize
        ActiveRecord::Base.connection.execute(
          "UPDATE topics SET title = #{ActiveRecord::Base.connection.quote(standardized_title)} 
           WHERE id = #{primary.id}"
        )
        
        # Move all definitions from other topics to the primary
        topics[1..-1].each do |duplicate|
          puts "  Merging '#{duplicate.title}' into '#{primary.title}'"
          
          # Move definitions using raw SQL
          ActiveRecord::Base.connection.execute(
            "UPDATE definitions SET topic_id = #{primary.id} 
             WHERE topic_id = #{duplicate.id}"
          )
          
          # Move relationships if they exist
          if defined?(TopicRelationship)
            ActiveRecord::Base.connection.execute(
              "UPDATE topic_relationships SET topic_id = #{primary.id} 
               WHERE topic_id = #{duplicate.id}"
            )
            ActiveRecord::Base.connection.execute(
              "UPDATE topic_relationships SET related_topic_id = #{primary.id} 
               WHERE related_topic_id = #{duplicate.id}"
            )
          end
          
          # Delete the duplicate using raw SQL
          ActiveRecord::Base.connection.execute(
            "DELETE FROM topics WHERE id = #{duplicate.id}"
          )
        end
      end
      
      # Now standardize all remaining titles
      puts "\nStandardizing remaining titles..."
      Topic.find_each do |topic|
        normalized = topic.title.downcase.strip
        standardized_title = Topic::SPECIAL_CASES[normalized] || topic.title.titleize
        
        if topic.title != standardized_title
          puts "  Updating '#{topic.title}' to '#{standardized_title}'"
          ActiveRecord::Base.connection.execute(
            "UPDATE topics SET title = #{ActiveRecord::Base.connection.quote(standardized_title)} 
             WHERE id = #{topic.id}"
          )
        end
      end
      
      # Recreate the unique index
      puts "\nRecreating unique index..."
      ActiveRecord::Base.connection.execute(
        "CREATE UNIQUE INDEX index_topics_on_title ON topics (title);"
      )
    end
    
    puts "\nTitle standardization completed!"
    puts "Total topics remaining: #{Topic.count}"
  end
end 