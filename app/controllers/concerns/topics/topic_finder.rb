module Topics
  module TopicFinder
    extend ActiveSupport::Concern

    included do
      before_action :set_topic
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