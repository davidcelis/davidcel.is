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
    unless images.all? { |image| image.webp_variant_attachment.analyzed? }
      logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
      SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
      return
    end

    text = case post
    when Note
      content = post.content

      # If the content is longer than 300 characters, we'll truncate it and
      # append a link to the full post.
      if character_count(content) > 300
        url = polymorphic_url(post)

        # Truncate the content so that it and the URL (23 characters),
        # separated by an ellipsis and a space, fit within the 500 character
        # limit.
        content = content.truncate(500 - 25, omission: "")
        content << "… #{url}"
      end

      content
    when Link
      content = [post.content, post.link_data["url"]].compact_blank.join("\n\n")

      (character_count(content) <= 300) ? content : "🔗 #{post.title}\n\n#{link_url(post)}"
    when CheckIn
      content = post.content.presence

      pin = content ? "📍 At " : "📍 I checked in at "
      pin << "#{post.place.name} / #{post.place.city_state_and_country(separator: " / ")}"
      candidate = [content, pin].compact.join("\n\n")

      # If the content is too long for everything to fit in 300 characters,
      # we'll truncate the content and append a link to the full post. The pin
      # will end up coming through in the link's preview, so we can ignore that.
      if character_count(candidate) > 300
        url = check_in_url(post)

        content = content.truncate(300 - 25, omission: "")
        content << "… #{url}"
      else
        content = candidate
      end

      content
    end

    text, facets = client.extract_facets(text)

    blobs = images.map do |media_attachment|
      result = client.upload_blob(media_attachment)
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

  # Bluesky supports up to 300 characters, but with a bit of control over how
  # things like URLs are represented, thanks to the convoluted use of facets.
  # Mentions still use the full character count, but URLs are basically rich
  # text. On our end, though, we just simulate what Mastodon does, truncating
  # links to a total of 23 characters (a schemeless URL with an ellipsis).
  def character_count(text)
    text.gsub(Post::URL_REGEX, "x" * 23).length
  end

  def client
    @client ||= ATProto::Client.new(
      identifier: Rails.application.credentials.dig(:at_proto, :identifier),
      password: Rails.application.credentials.dig(:at_proto, :app_password)
    )
  end
end
