class StandardizeExistingTopicTitles < ActiveRecord::Migration[8.0]
  def change
    Topic.find_each do |topic|
      next if topic.title == topic.title.downcase
      
      old_title = topic.title
      topic.update_column(:title, topic.title.downcase)
      say "Standardized title: '#{old_title}' -> '#{topic.title}'"
    end
  end
end