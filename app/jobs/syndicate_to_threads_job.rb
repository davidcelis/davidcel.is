class SyndicateToThreadsJob < ApplicationJob
  Error = Class.new(StandardError)

  include Rails.application.routes.url_helpers

  def perform(post_id)
    # If we haven't authenticated with Threads, we can't syndicate to it yet.
    return unless Threads::Credential.exists?

    post = Post.find(post_id)

    if !post.is_a?(Article) && post.media_attachments.any? && !post.media_attachments.all?(&:analyzed?)
      logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
      return SyndicateToThreadsJob.perform_in(5.seconds, post_id)
    end

    text = case post
    when Article
      "“#{post.title}”\n\n#{article_url(post)}"
    when Note
      content = post.content

      # If the content is longer than 500 characters, we'll truncate it and
      # append a link to the full post.
      if content.length > 500
        url = polymorphic_url(post)

        # Truncate the content so that it and the URL, separated by an ellipsis
        # and a space, fit within the 500 character limit.
        content = content.truncate(500 - url.length - 2, omission: "")
        content << "… #{url}"
      end

      content
    when Link
      content = [post.content, post.link_data["url"]].compact_blank.join("\n\n")

      (content.length <= 500) ? content : "🔗 #{post.title}\n\n#{link_url(post)}"
    when CheckIn
      content = post.content.presence

      pin = content ? "📍" : "📍I checked in at "
      pin << "#{post.place.name} / #{post.place.city_state_and_country(separator: " / ")}"
      candidate = [content, pin].compact.join("\n\n")

      # If the content is too long for everything to fit in 500 characters,
      # we'll truncate the content and append a link to the full post. The pin
      # will end up coming through in the link's preview, so we can ignore that.
      if candidate.length > 500
        url = check_in_url(post)

        content = content.truncate(500 - url.length - 2, omission: "")
        content << "… #{url}"
      else
        content = candidate
      end

      content
    end

    pending_thread = nil

    # If the post has more than one media attachment, we'll need to upload them
    # all the Threads separately as carousel items. If there's only one media
    # attachment, we can upload it as a single image/video post.
    if post.media_attachments.count > 1
      carousel_items = post.media_attachments.map do |media_attachment|
        if media_attachment.image?
          client.create_carousel_item(type: "IMAGE", image_url: cdn_file_url(media_attachment.file))
        elsif media_attachment.video?
          client.create_carousel_item(type: "VIDEO", video_url: cdn_file_url(media_attachment.file))
        else
          logger.warn("Unsupported media type: #{media_attachment.content_type}")
        end
      end

      pending_thread = client.create_carousel_thread(text: text, children: carousel_items.map(&:id))
    else
      media_attachment = post.media_attachments.first

      options = {text: text}
      if media_attachment&.image?
        options[:type] = "IMAGE"
        options[:image_url] = cdn_file_url(media_attachment.file)
      elsif media_attachment&.video?
        options[:type] = "VIDEO"
        options[:video_url] = cdn_file_url(media_attachment.file)
      end

      pending_thread = client.create_thread(**options)
    end

    pending_thread = client.get_thread_status(pending_thread.id)
    while pending_thread.in_progress?
      sleep 5
      pending_thread = client.get_thread_status(pending_thread.id)
    end

    if pending_thread.errored?
      raise Error, "Failed to create thread: #{pending_thread.error_message}"
    elsif pending_thread.expired?
      raise Error, "Thread creation timed out."
    elsif pending_thread.published?
      logger.info("Thread was already published.")
    end

    thread = client.publish_thread(pending_thread.id)
    thread = client.get_thread(thread.id, fields: "permalink")

    post.syndication_links.create!(
      platform: "threads",
      url: thread.permalink
    )
  end

  private

  def client
    @client ||= Threads::API::Client.new(Threads::Credential.sole.access_token)
  end
end
