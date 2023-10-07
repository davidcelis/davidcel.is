class SyndicateToMastodonJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(post_id)
    post = Post.find(post_id)

    content = case post
    when Note
      post.content
    when Article
      "“#{post.title}”\n\n#{article_url(post)}"
    when CheckIn
      text = post.content.presence

      pin = text ? "📍 At " : "📍 I checked in at "
      pin << "#{post.place.name} / #{post.place.city_state_and_country(separator: " / ")}"
      candidate = [text, pin].compact.join("\n\n")

      (candidate.length > 500) ? content : candidate
    end

    media_ids = []
    if post.media_attachments.any? && !post.is_a?(Article)
      # Wait if any of the media attachments are still waiting to be analyzed.
      unless post.media_attachments.all?(&:analyzed)
        logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
        SyndicateToMastodonJob.perform_in(5.seconds, post_id)
        return
      end

      post.media_attachments.each do |media_attachment|
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
