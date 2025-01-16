module Topics
  module People
    class KnowledgeGraphSearchController < ApplicationController
      include Topics::TopicFinder
      before_action :authenticate

      def new
        if params[:query].present?
          @results = KnowledgeGraphService.search(params[:query])
        else
          @results = []
        end
      end

      def create
        @person = Person.find_by(google_knowledge_id: person_params[:google_knowledge_id])

        if @person
          @topic.people << @person unless @topic.people.include?(@person)
        else
          @person = Person.create!(
            title: person_params[:title],
            google_knowledge_id: person_params[:google_knowledge_id],
            metadata: {
              knowledge_graph: {
                description: person_params[:description],
                detailed_description: person_params.dig(:metadata, :knowledge_graph, :detailed_description),
                url: person_params.dig(:metadata, :knowledge_graph, :url),
                image_url: person_params[:image_url]
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
          :title, :google_knowledge_id, :description, :image_url,
          metadata: { knowledge_graph: [:detailed_description, :url] }
        )
      end
    end
  end
end 