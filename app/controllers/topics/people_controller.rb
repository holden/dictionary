module Topics
  class PeopleController < ApplicationController
    before_action :authenticate
    before_action :set_topic
    
    def index
      @people = @topic.people.order(created_at: :desc)
    end

    def create
      person_data = TmdbService.new.person_details(params[:tmdb_id])
      @person = Person.find_or_initialize_by(tmdb_id: person_data[:tmdb_id])
      
      @person.assign_attributes(
        title: person_data[:name],
        metadata: {
          tmdb: {
            profile_path: person_data[:profile_path],
            known_for_department: person_data[:known_for_department],
            biography: person_data[:biography],
            imdb_id: person_data[:imdb_id]
          }
        }
      )
      
      if @person.save
        @topic.people << @person unless @topic.people.include?(@person)
        redirect_to send("#{@topic.route_key}_people_path", @topic), 
          notice: 'Person was successfully added.'
      else
        redirect_to search_tmdb_concept_people_path(@topic), 
          alert: 'Could not add person.'
      end
    end

    def destroy
      @person = Person.friendly.find(params[:id])
      @topic.people.delete(@person)

      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_people_path", @topic), notice: "Person was successfully removed." }
        format.turbo_stream { 
          flash.now[:notice] = "Person was successfully removed."
          render turbo_stream: [
            turbo_stream.remove(@person),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
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
  end
end 