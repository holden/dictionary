module Topics
  class LyricsController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_topic
    before_action :set_lyric, only: [:show, :destroy]

    def index
      @lyrics = @topic.lyrics.order(created_at: :desc)
    end

    def show
      # @lyric is set by before_action :set_lyric
    end

    def new
      @lyric = Lyric.new(topic: @topic)
    end

    def create
      # Try to find existing lyric first
      @lyric = Lyric.find_by(source_url: lyric_params[:source_url]) if lyric_params[:source_url].present?
      
      if @lyric
        # Check if this topic already has this lyric
        if @topic.lyrics.exists?(@lyric.id)
          redirect_to send("#{@topic.route_key}_lyrics_path", @topic), 
            alert: 'This lyric has already been added to this topic.'
          return
        end
      else
        # Create new lyric if none exists
        @lyric = Lyric.new(lyric_params)
        @lyric.user = Current.user

        # Handle author resolution
        if @lyric.attribution_text.present?
          Rails.logger.info "Resolving author for: #{@lyric.attribution_text}"
          
          if author = Person.find_by("lower(title) = ?", @lyric.attribution_text.downcase)
            Rails.logger.info "Found existing author: #{author.title}"
            @lyric.author = author
          else
            Rails.logger.info "Creating new artist: #{@lyric.attribution_text}"
            person = Person.create!(
              title: @lyric.attribution_text,
              slug: @lyric.attribution_text.parameterize,
              metadata: {
                genius: @lyric.metadata&.dig('genius')&.slice('artist_id', 'artist_url')
              }
            )
            Rails.logger.info "Created artist: #{person.title}"
            @lyric.author = person
          end
        end

        unless @lyric.save
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { 
              flash.now[:alert] = @lyric.errors.full_messages.to_sentence
              render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), 
                status: :unprocessable_entity
            }
          end
          return
        end
      end

      # Associate with topic
      @topic.lyrics << @lyric

      respond_to do |format|
        format.html { 
          redirect_to send("#{@topic.route_key}_lyrics_path", @topic), 
            notice: 'Lyric was successfully added.' 
        }
        format.turbo_stream do
          flash.now[:notice] = 'Lyric was successfully added.'
          render turbo_stream: [
            turbo_stream.prepend("lyrics", partial: "topics/lyrics/lyric", locals: { lyric: @lyric }),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    def destroy
      @lyric.destroy

      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_lyrics_path", @topic), notice: 'Lyric was successfully removed.' }
        format.turbo_stream do
          flash.now[:notice] = 'Lyric was successfully removed.'
          render turbo_stream: [
            turbo_stream.remove(@lyric),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
      end
    end

    private

    def set_topic
      @topic = Topic.find_by!(type: type_param.classify, slug: params[:other_id])
    end

    def set_lyric
      @lyric = @topic.lyrics.find(params[:id])
    end

    def type_param
      params[:type].underscore
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