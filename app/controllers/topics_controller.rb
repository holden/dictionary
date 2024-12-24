class TopicsController < ApplicationController
  def index
    # Get all topics, ordered by title
    @topics = Topic.includes(:definitions => [:source, :author])
                  .order(:title)
                  .group_by { |topic| topic.title[0].upcase }
    
    # Get unique first letters for navigation
    @letters = @topics.keys.sort
  end
end 