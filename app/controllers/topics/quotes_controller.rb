module Topics
  class QuotesController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_quote, only: [:destroy]

    def index
      @quotes = @topic.quotes.order(created_at: :desc)
    end

    def new
      @quote = Quote.new
    end

    def create
      # Try to find existing quote first
      @quote = Quote.find_by(source_url: quote_params[:source_url]) if quote_params[:source_url].present?
      
      if @quote
        # Check if this topic already has this quote
        if @topic.quotes.exists?(@quote.id)
          redirect_to send("#{@topic.route_key}_quotes_path", @topic), 
            alert: 'This quote has already been added to this topic.'
          return
        end
      else
        # Create new quote if none exists
        @quote = Quote.new(quote_params)
        @quote.user = Current.user

        # Handle author resolution
        if @quote.attribution_text.present?
          Rails.logger.info "Resolving author for: #{@quote.attribution_text}"
          
          if author = Person.find_by("lower(title) = ?", @quote.attribution_text.downcase)
            Rails.logger.info "Found existing author: #{author.title}"
            @quote.author = author
          else
            Rails.logger.info "Author not found in database, trying OpenLibrary..."
            
            if author_data = OpenLibraryService.search_author(@quote.attribution_text)
              person = Person.create!(
                title: @quote.attribution_text,
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

        unless @quote.save
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { 
              flash.now[:alert] = @quote.errors.full_messages.to_sentence
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), 
                status: :unprocessable_entity
            }
          end
          return
        end
      end

      # Associate with topic
      @topic.quotes << @quote

      respond_to do |format|
        format.html { 
          redirect_to send("#{@topic.route_key}_quotes_path", @topic), 
            notice: 'Quote was successfully added.' 
        }
        format.turbo_stream do
          flash.now[:notice] = 'Quote was successfully added.'
          render turbo_stream: [
            turbo_stream.prepend("quotes", partial: "topics/quotes/quote", locals: { quote: @quote }),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    def destroy
      @quote.destroy

      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_quotes_path", @topic), notice: 'Quote was successfully removed.' }
        format.turbo_stream do
          flash.now[:notice] = 'Quote was successfully removed.'
          render turbo_stream: [
            turbo_stream.remove(@quote),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    private

    def set_quote
      @quote = @topic.quotes.find(params[:id])
    end

    def quote_params
      params.require(:quote).permit(
        :content, :attribution_text, :citation,
        :source_url, :disputed, :misattributed,
        metadata: {}
      )
    end
  end
end 