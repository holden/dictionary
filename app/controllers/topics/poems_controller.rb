module Topics
  class PoemsController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_poem, only: [:destroy]

    def index
      @poems = @topic.poems.order(created_at: :desc)
    end

    def new
      @poem = Poem.new
    end

    def search
      @search_term = params[:q]
      @author = params[:author]
      
      if @search_term.present? || @author.present?
        @results = if @author.present?
          PoetryDBService.search_by_author(@author)
        else
          PoetryDBService.search_by_title(@search_term)
        end
      end
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      # Try to find existing poem first
      @poem = Poem.find_by(source_title: poem_params[:source_title]) if poem_params[:source_title].present?
      
      if @poem
        # Check if this topic already has this poem
        if @topic.poems.exists?(@poem.id)
          redirect_to send("#{@topic.route_key}_poems_path", @topic), 
            alert: 'This poem has already been added to this topic.'
          return
        end
      else
        # Create new poem if none exists
        @poem = Poem.new(poem_params)
        @poem.user = Current.user

        # Handle author resolution
        if @poem.attribution_text.present?
          Rails.logger.info "Resolving author for: #{@poem.attribution_text}"
          
          if author = Person.find_by("lower(title) = ?", @poem.attribution_text.downcase)
            Rails.logger.info "Found existing author: #{author.title}"
            @poem.author = author
          else
            Rails.logger.info "Creating new poet: #{@poem.attribution_text}"
            person = Person.create!(
              title: @poem.attribution_text,
              slug: @poem.attribution_text.parameterize
            )
            Rails.logger.info "Created poet: #{person.title}"
            @poem.author = person
          end
        end

        unless @poem.save
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { 
              flash.now[:alert] = @poem.errors.full_messages.to_sentence
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), 
                status: :unprocessable_entity
            }
          end
          return
        end
      end

      # Associate with topic
      @topic.poems << @poem

      respond_to do |format|
        format.html { 
          redirect_to send("#{@topic.route_key}_poems_path", @topic), 
            notice: 'Poem was successfully added.' 
        }
        format.turbo_stream do
          flash.now[:notice] = 'Poem was successfully added.'
          render turbo_stream: [
            turbo_stream.prepend("poems", partial: "topics/poems/poem", locals: { poem: @poem }),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    def destroy
      @poem.destroy

      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_poems_path", @topic), notice: 'Poem was successfully removed.' }
        format.turbo_stream do
          flash.now[:notice] = 'Poem was successfully removed.'
          render turbo_stream: [
            turbo_stream.remove(@poem),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    private

    def set_poem
      @poem = @topic.poems.find(params[:id])
    end

    def poem_params
      params.require(:poem).permit(
        :content, :attribution_text, :source_title,
        :year_written, metadata: {}
      )
    end
  end
end 