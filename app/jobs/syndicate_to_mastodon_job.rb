class SyndicateToMastodonJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(post_id)
    post = Post.find(post_id)

    content = case post
    when Note
      post.content
    when Article
      "“#{post.title}”\n\n#{article_url(post)}"
    end

    media_ids = []
    if post.is_a?(Note) && post.media_attachments.any?
      post.media_attachments.map do |media_attachment|
        response = client.upload_media(media_attachment)
        media_ids << response["id"]
      end
    end

    status = client.create_status(content: content, media_ids: media_ids, idempotency_key: post.id)

    post.syndication_links.create!(
      platform: "mastodon",
      url: status["url"]
    )
  end

  private

  def client
    @client ||= Mastodon::Client.new
  end
end
