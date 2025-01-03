module SemanticDataHelper
  include Rails.application.routes.url_helpers

  def open_graph_tags(topic)
    {
      'og:title' => topic.display_title,
      'og:type' => 'article',
      'og:url' => topic_url(topic, host: request.base_url),
      'og:description' => topic.first_definition&.content&.to_plain_text&.truncate(200) || "Definition of #{topic.display_title}",
      'og:site_name' => "Post-Modern Devil's Dictionary",
      'og:locale' => 'en_US'
    }
  end

  def json_ld_data(topic)
    {
      '@context' => 'https://schema.org',
      '@type' => 'Definition',
      'name' => topic.display_title,
      'inLanguage' => 'en',
      'author' => {
        '@type' => 'Organization',
        'name' => "Post-Modern Devil's Dictionary",
        'url' => root_url
      },
      'datePublished' => topic.created_at.iso8601,
      'dateModified' => topic.updated_at.iso8601,
      'description' => topic.first_definition&.content&.to_plain_text,
      'url' => topic_url(topic),
      'image' => topic_image_url(topic),
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => topic_url(topic)
      }
    }.compact
  end

  private

  def topic_image_url(topic)
    return nil unless @gifs&.any?
    
    # Use the first GIF as the social sharing image
    gif = @gifs.first
    if gif[:url].present?
      # Ensure the URL is absolute and uses HTTPS
      url = URI.join(root_url, gif[:url]).to_s
      url.gsub('http://', 'https://')
    end
  end
end 