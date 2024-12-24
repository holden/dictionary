namespace :topics do
  desc "Generate slugs for existing topics"
  task generate_slugs: :environment do
    Topic.find_each(&:save)
  end
end 