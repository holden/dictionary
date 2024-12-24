class TopicsController < ApplicationController
  def index
    # Get only topics with definitions, ordered by title
    @topics = Topic.joins(:definitions)
                  .includes(:definitions => [:source, :author])
                  .includes(:related_topics)
                  .distinct
                  .order(:title)
                  .group_by { |topic| topic.title[0].upcase }
    
    # Get unique first letters for navigation
    @letters = @topics.keys.sort
  end
end 