namespace :dictionary do
  desc "Import entries from The Verge's New Devil's Dictionary"
  task verge: :environment do
    load Rails.root.join('db/seeds/new_devils_dictionary.rb')
  end

  desc "Import entries from Ambrose Bierce's Devil's Dictionary"
  task bierce: :environment do
    load Rails.root.join('db/seeds/devils_dictionary.rb')
  end

  desc "Import all dictionary entries"
  task all: [:bierce, :verge]
end 