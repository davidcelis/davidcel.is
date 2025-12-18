class SyndicateToMastodonJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::SanitizeHelper

  def perform(post_id)
    post = Post.find(post_id)

    content = case post
    when Article
      url = article_url(post)
      excerpt = post.og_description.truncate(500 - 25, omission: "…")

      "#{excerpt}\n\n#{url}"
    when Note
      text = post.content

      # If the content is longer than 500 characters, we'll truncate it and
      # append a link to the full post.
      if character_count(text) > 500
        url = polymorphic_url(post)

        # Truncate the content so that it and the URL (23 characters),
        # separated by an ellipsis and a space, fit within the 500 character
        # limit.
        text = text.truncate(500 - 25, omission: "")
        text << "… #{url}"
      end

      text
    when Link
      text = [post.content, post.link_data["url"]].compact_blank.join("\n\n")

      (character_count(text) <= 500) ? text : "🔗 #{post.title}\n\n#{link_url(post)}"
    when CheckIn
      text = post.content.presence

      pin = text ? "📍" : "📍I checked in at "
      pin << "#{post.place.name} / #{post.place.city_state_and_country(separator: " / ")}"
      candidate = [text, pin].compact.join("\n\n")

      # If the content is too long for everything to fit in 500 characters,
      # we'll truncate the content and append a link to the full post. The pin
      # will end up coming through in the link's preview, so we can ignore that.
      if character_count(candidate) > 500
        url = check_in_url(post)

        text = text.truncate(500 - 25, omission: "")
        text << "… #{url}"
      else
        text = candidate
      end

      text
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

    if (link = post.syndication_links.find_by(platform: "mastodon"))
      status_id = link.url.split("/").last
      client.update_status(status_id, content: content, media_ids: media_ids)
    else
      status = client.create_status(content: content, media_ids: media_ids, idempotency_key: post.id)
      post.syndication_links.create!(
        platform: "mastodon",
        url: status["url"]
      )
    end
  end

  private

  def client
    @client ||= Mastodon::Client.new
  end

  # Mastodon supports up to 500 characters, but certain things like URLs and
  # @mentions don't use up their full character count. Links are shortened
  # automatically to only use 23 characters, and @mentions don't use any space
  # at and after the second @ symbol.
  def character_count(text)
    text.gsub(Post::URL_REGEX, "x" * 23).gsub(Post::MASTODON_MENTION_REGEX, "@#{$1}").length
  end
end
