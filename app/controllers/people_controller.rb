class PeopleController < ApplicationController
  before_action :set_topic

  def search
    @results = case params[:source]
    when 'tmdb'
      TmdbService.new.search_people(@topic.title)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    person_data = TmdbService.new.person_details(params[:tmdb_id])
    
    @person = Person.find_or_initialize_by(tmdb_id: person_data[:tmdb_id])
    @person.assign_attributes(person_data)
    
    if @person.save
      @topic.people << @person unless @topic.people.include?(@person)
      
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.append(
            "topic_people",
            partial: "topics/person",
            locals: { person: @person }
          )
        }
        format.html { redirect_to @topic }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_topic
    @topic = Topic.friendly.find(params[:id])
  end
end 