class FetchTopicQuotesJob < ApplicationJob
  queue_as :default
  
  def perform(topic)
    quotes = WikiQuotesService.new(topic.title).fetch_quotes
    
    quotes.each do |quote_content|
      topic.quotes.create!(content: quote_content)
    end
  end
end 