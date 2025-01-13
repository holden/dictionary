module Topics
  module TopicFinder
    extend ActiveSupport::Concern

    private

    def set_topic
      param_key = params.each_key.find { |k| k.to_s.end_with?('_id') }
      @topic = Topic.find_by!(slug: params[param_key])
    end
  end
end 