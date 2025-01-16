module Topics
  module People
    class TmdbSearchController < ApplicationController
      include Topics::TopicFinder
      before_action :authenticate

      def new
        if params[:query].present?
          @results = tmdb_service.search_people(params[:query])
        else
          @results = []
        end
      end

      def create
        @person = Person.find_by(tmdb_id: person_params[:tmdb_id])

        if @person
          @topic.people << @person unless @topic.people.include?(@person)
        else
          @person = Person.create!(
            title: person_params[:name],
            tmdb_id: person_params[:tmdb_id],
            metadata: {
              tmdb: {
                known_for_department: person_params[:known_for_department],
                popularity: person_params[:popularity],
                profile_path: person_params[:profile_path]
              }
            }
          )
          @topic.people << @person
        end

        respond_to do |format|
          format.turbo_stream { 
            flash.now[:notice] = "Added #{@person.title} to #{@topic.title}"
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

      def person_params
        params.require(:person).permit(
          :name, :tmdb_id, :known_for_department, :popularity, :profile_path
        )
      end

      def tmdb_service
        @tmdb_service ||= TmdbService.new
      end
    end
  end
end 