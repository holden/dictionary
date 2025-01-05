namespace :backfill do
  desc "Backfill external IDs for topics and books"
  task external_ids: :environment do
    # Backfill ConceptNet IDs for non-Person topics
    Topic.where.not(type: 'Person').find_each do |topic|
      next if topic.concept_net_id.present?
      puts "Processing ConceptNet ID for #{topic.title}..."
      topic.send(:ensure_concept_net_id)
    end

    # Backfill OpenLibrary IDs for Person topics
    Topic.where(type: 'Person').find_each do |topic|
      next if topic.open_library_id.present?
      puts "Processing OpenLibrary ID for #{topic.title}..."
      topic.send(:ensure_open_library_id)
    end

    # Backfill OpenLibrary IDs for books
    Book.find_each do |book|
      next if book.open_library_id.present?
      puts "Processing OpenLibrary ID for #{book.title}..."
      book.send(:ensure_open_library_id)
    end
  end
end 