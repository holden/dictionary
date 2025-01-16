module Topics
  class PeopleController < ApplicationController
    include Topics::TopicFinder
    before_action :authenticate
    before_action :set_person, only: [:destroy]

    def index
      @people = @topic.people.order(created_at: :desc)
    end

    def destroy
      @topic.people.delete(@person)
      respond_to do |format|
        format.turbo_stream { 
          flash.now[:notice] = "Removed #{@person.title} from #{@topic.title}"
          @people = @topic.people.order(created_at: :desc)
          render turbo_stream: [
            turbo_stream.update("content", template: "topics/people/index"),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
        format.html { redirect_to send("#{@topic.route_key}_people_path", @topic) }
      end
    end

    private

    def set_person
      @person = Person.friendly.find(params[:id])
    end
  end
end 