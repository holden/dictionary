namespace :conceptnet do
  desc "Update missing ConceptNet IDs for topics"
  task update_missing_ids: :environment do
    topics = Topic.where(conceptnet_id: nil)
    total = topics.count
    updated = 0

    puts "Found #{total} topics missing ConceptNet IDs"

    topics.find_each.with_index do |topic, index|
      # Skip people since we don't want ConceptNet IDs for them
      next if topic.type == "Person"

      if result = ConceptNetService.lookup(topic.title)
        topic.update_column(:conceptnet_id, result['id'])
        updated += 1
        puts "#{index + 1}/#{total}: Updated '#{topic.title}' with ID: #{result['id']}"
      else
        puts "#{index + 1}/#{total}: No match found for '#{topic.title}'"
      end
    end

    puts "\nCompleted! Updated #{updated} out of #{total} topics"
  end
end 