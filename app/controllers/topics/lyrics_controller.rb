module Topics
  class LyricsController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_lyric, only: [:destroy]

    def index
      @lyrics = @topic.lyrics.order(created_at: :desc)
    end

    def new
      @lyric = Lyric.new(topic: @topic)
    end

    def create
      @lyric = Lyric.new(lyric_params)
      @lyric.topic = @topic
      @lyric.user = Current.user

      # Try to resolve the author
      if @lyric.attribution_text.present?
        Rails.logger.info "Resolving author for: #{@lyric.attribution_text}"
        
        # Try finding in our database first
        if author = Person.find_by("lower(title) = ?", @lyric.attribution_text.downcase)
          Rails.logger.info "Found existing author: #{author.title}"
          @lyric.author = author
        else
          Rails.logger.info "Author not found in database, trying OpenLibrary..."
          
          # Try creating from OpenLibrary if not found
          if author_data = OpenLibraryService.search_author(@lyric.attribution_text)
            person = Person.create!(
              title: @lyric.attribution_text.downcase,
              slug: @lyric.attribution_text.parameterize,
              open_library_id: author_data['key'],
              metadata: {
                openlibrary: {
                  birth_date: author_data['birth_date'],
                  death_date: author_data['death_date']
                }
              }
            )
            Rails.logger.info "Created author from OpenLibrary: #{person.title}"
            @lyric.author = person
          end
        end
      end

      if @lyric.save
        respond_to do |format|
          format.turbo_stream { 
            redirect_to send("#{@topic.route_key}_lyrics_path", @topic), notice: 'Lyric was successfully created.'
          }
          format.html { redirect_to send("#{@topic.route_key}_lyrics_path", @topic), notice: 'Lyric was successfully created.' }
        end
      else
        # Check if the error is due to a duplicate lyric
        if @lyric.errors[:source_url].include?('has already been taken')
          redirect_to send("#{@topic.route_key}_lyrics_path", @topic), 
            alert: 'This lyric has already been added to the database.'
        else
          Rails.logger.error "Failed to save lyric: #{@lyric.errors.full_messages}"
          render :new, status: :unprocessable_entity
        end
      end
    end

    def destroy
      @lyric.destroy
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.remove(@lyric),
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Lyric was successfully removed." })
          ]
        }
        format.html { redirect_to send("#{@topic.route_key}_lyrics_path", @topic), notice: 'Lyric was successfully removed.' }
      end
    end

    private

    def set_lyric
      @lyric = @topic.lyrics.find(params[:id])
    end

    def lyric_params
      params.require(:lyric).permit(
        :content, :attribution_text, :citation,
        :source_url, :source_title,
        :year_written,
        metadata: {}
      )
    end
  end
end 