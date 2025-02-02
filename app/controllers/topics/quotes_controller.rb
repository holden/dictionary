module Topics
  class QuotesController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_quote, only: [:destroy]

    def index
      @quotes = @topic.quotes.order(created_at: :desc)
    end

    def new
      @quote = Quote.new(topic: @topic)
    end

    def create
      @quote = Quote.new(quote_params)
      @quote.topic = @topic
      @quote.user = Current.user

      # Try to resolve the author
      if @quote.attribution_text.present?
        Rails.logger.info "Resolving author for: #{@quote.attribution_text}"
        
        # Try finding in our database first
        if author = Person.find_by("lower(title) = ?", @quote.attribution_text.downcase)
          Rails.logger.info "Found existing author: #{author.title}"
          @quote.author = author
        else
          Rails.logger.info "Author not found in database, trying OpenLibrary..."
          
          # Try creating from OpenLibrary if not found
          if author_data = OpenLibraryService.search_author(@quote.attribution_text)
            person = Person.create!(
              title: @quote.attribution_text.downcase,
              slug: @quote.attribution_text.parameterize,
              open_library_id: author_data['key'],
              metadata: {
                openlibrary: {
                  birth_date: author_data['birth_date'],
                  death_date: author_data['death_date']
                }
              }
            )
            Rails.logger.info "Created author from OpenLibrary: #{person.title}"
            @quote.author = person
          end
        end
      end

      if @quote.save
        respond_to do |format|
          format.turbo_stream { 
            redirect_to send("#{@topic.route_key}_quotes_path", @topic), notice: 'Quote was successfully created.'
          }
          format.html { redirect_to send("#{@topic.route_key}_quotes_path", @topic), notice: 'Quote was successfully created.' }
        end
      else
        # Check if the error is due to a duplicate quote
        if @quote.errors[:source_url].include?('has already been taken')
          redirect_to send("#{@topic.route_key}_quotes_path", @topic), 
            alert: 'This quote has already been added to the database.'
        else
          Rails.logger.error "Failed to save quote: #{@quote.errors.full_messages}"
          render :new, status: :unprocessable_entity
        end
      end
    end

    def destroy
      @quote.destroy
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.remove(@quote),
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Quote was successfully removed." })
          ]
        }
        format.html { redirect_to send("#{@topic.route_key}_quotes_path", @topic), notice: 'Quote was successfully removed.' }
      end
    end

    private

    def set_quote
      @quote = @topic.quotes.find(params[:id])
    end

    def quote_params
      params.require(:quote).permit(
        :content, :attribution_text, :citation,
        :disputed, :misattributed,
        :original_language, :original_text,
        :source_url,
        metadata: {}
      )
    end
  end
end 