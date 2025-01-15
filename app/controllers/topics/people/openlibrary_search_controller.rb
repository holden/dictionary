module Topics
  module People
    class OpenlibrarySearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic
      
      def new
        if params[:query].present?
          @results = OpenLibraryService.new.search_authors(params[:query])
        end
        
        render 'topics/people/search_openlibrary'
      end

      def create
        person_data = JSON.parse(params[:person])
        
        @person = Person.find_or_initialize_by(open_library_id: person_data['open_library_id'])
        
        @person.assign_attributes({
          title: person_data['name'],
          open_library_id: person_data['open_library_id'],
          metadata: {
            openlibrary: {
              birth_date: person_data['birth_date'],
              death_date: person_data['death_date']
            }
          }
        })

        if @person.save
          @topic.people << @person unless @topic.people.include?(@person)
          
          respond_to do |format|
            format.html { redirect_to send("#{@topic.route_key}_people_path", @topic), notice: "#{@person.title} was successfully added." }
            format.turbo_stream { 
              flash.now[:notice] = "#{@person.title} was successfully added."
              @people = @topic.people.order(created_at: :desc)
              render turbo_stream: [
                turbo_stream.update("content", template: "topics/people/index"),
                turbo_stream.update("flash", partial: "shared/flash")
              ]
            }
          end
        else
          render :new, status: :unprocessable_entity
        end
      end

      private

      def set_topic
        param_key = case params[:type]&.downcase
          when 'concept' then :concept_id
          when 'place' then :place_id
          when 'thing' then :thing_id
          when 'event' then :event_id
          when 'action' then :action_id
          when 'other' then :other_id
          else
            raise ActionController::ParameterMissing, "Missing topic type parameter"
        end

        @topic = Topic.friendly.find(params[param_key])
        
        unless @topic.type.downcase == params[:type].downcase
          redirect_to root_path, alert: "Topic not found"
        end
      end

      def person_params
        params.require(:person).permit!
      end
    end
  end
end 