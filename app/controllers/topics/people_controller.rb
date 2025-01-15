module Topics
  class PeopleController < ApplicationController
    before_action :authenticate
    before_action :set_topic
    
    def index
      @people = @topic.people.order(created_at: :desc)
    end

    def create
      @person = Person.find_or_initialize_by(tmdb_id: person_params[:tmdb_id])
      
      # Map TMDB attributes to our model's attributes
      @person.assign_attributes({
        title: person_params[:name],
        tmdb_id: person_params[:tmdb_id],
        metadata: {
          tmdb: {
            known_for_department: person_params[:known_for_department],
            popularity: person_params[:popularity],
            profile_path: person_params[:profile_path]
          }
        }
      })

      if @person.save
        @topic = find_topic
        @topic.people << @person unless @topic.people.include?(@person)
        
        respond_to do |format|
          format.html { redirect_to send("#{@topic.route_key}_people_path", @topic), notice: "#{@person.title} was successfully added." }
          format.turbo_stream { 
            @people = @topic.people.order(created_at: :desc)
            render turbo_stream: turbo_stream.update("content", 
              template: "topics/people/index"
            )
          }
        end
      else
        render :new, status: :unprocessable_entity
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

    def person_params
      params.require(:person).permit(
        :name, 
        :tmdb_id, 
        :known_for_department, 
        :popularity, 
        :profile_path
      )
    end

    def find_topic
      param_key = params[:type].underscore
      param_value = params["#{param_key}_id"]
      param_key.classify.constantize.find_by!(slug: param_value)
    end
  end
end 