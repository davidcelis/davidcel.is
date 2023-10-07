class SyndicateToBlueskyJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(post_id)
    post = Post.find(post_id)

    # If the post is an Article, we'll just syndicate the title and URL.
    if post.is_a?(Article)
      text, facets = client.extract_facets("“#{post.title}”\n\n#{article_url(post)}")
      response = client.create_post(text: text, created_at: post.created_at, facets: facets)
      return create_syndication_link(post, response)
    end

    images = post.media_attachments.select(&:image?)
    unless images.all?(&:analyzed)
      logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
      SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
      return
    end

    text = case post
    when Note
      post.content
    when CheckIn
      content = post.content.presence

      pin = content ? "📍 At " : "📍 I checked in at "
      pin << "#{post.place.name} / #{post.place.city_state_and_country(separator: " / ")}"
      candidate = [content, pin].compact.join("\n\n")

      (candidate.length > 300) ? content : candidate
    end

    if text.length > 300
      url = polymorphic_url(post)

      # Truncate the content so that it, an ellipsis, and the URL fit within
      # the 300 character limit
      truncated_text = text[0...(300 - url.length - 2)]
      text = "#{truncated_text}… #{url}"
    end

    text, facets = client.extract_facets(text)

    blobs = images.map do |media_attachment|
      result = client.upload_blob(media_attachment, content_type: media_attachment.content_type)
      {image: result["blob"], alt: media_attachment.description}
    end

    response = client.create_post(text: text, created_at: post.created_at, facets: facets, images: blobs)
    create_syndication_link(post, response)
  ensure
    client.sign_out!
  end

  private

  # Once posted, the response will contain an at:// URI that can be used to
  # link to the post in Bluesky. For example:
  #
  # at://did:plc:4why37npqk7bbahxfer6ma47/app.bsky.feed.post/3k4i2hxxjki2a
  #
  # Thankfully, that last fragment is all we really need to construct a
  # link to the post in Bluesky:
  #
  # https://bsky.app/profile/davidcelis.bsky.social/post/3k4i2hxxjki2a
  def create_syndication_link(post, response)
    bluesky_id = response.body["uri"].split("/").last
    url = "https://bsky.app/profile/#{client.session.handle}/post/#{bluesky_id}"

    post.syndication_links.create!(platform: "bluesky", url: url)
  end

  def client
    @client ||= ATProto::Client.new(
      identifier: Rails.application.credentials.dig(:at_proto, :identifier),
      password: Rails.application.credentials.dig(:at_proto, :app_password)
    )
  end
end
