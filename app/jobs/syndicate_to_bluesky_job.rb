class SyndicateToBlueskyJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(post_id)
    post = Post.find(post_id)

    text = case post
    when Note
      if post.content && post.content.length > 300
        url = note_url(post)

        # Truncate the content so that it, an ellipsis, and the URL fit within
        # the 300 character limit
        content = post.content[0...(300 - url.length - 2)]
        "#{content}… #{url}"
      else
        post.content
      end
    when Article
      "“#{post.title}”\n\n#{article_url(post)}"
    end

    images = []
    if post.is_a?(Note) && post.media_attachments.any?(&:image?)
      # Wait if any of the media attachments are still waiting to be analyzed.
      unless post.media_attachments.all?(&:analyzed)
        logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
        SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
        return
      end

      post.media_attachments.select(&:image?).each do |media_attachment|
        result = client.upload_blob(media_attachment, content_type: media_attachment.content_type)
        images << {image: result["blob"], alt: media_attachment.description}
      end
    end

    response = client.create_post(text: text, created_at: post.created_at, images: images)

    # Once posted, the response will contain an at:// URI that can be used to
    # link to the post in Bluesky. For example:
    #
    # at://did:plc:4why37npqk7bbahxfer6ma47/app.bsky.feed.post/3k4i2hxxjki2a
    #
    # Thankfully, that last fragment is all we really need to construct a
    # link to the post in Bluesky:
    #
    # https://bsky.app/profile/davidcelis.bsky.social/post/3k4i2hxxjki2a
    bluesky_id = response.body["uri"].split("/").last
    url = "https://bsky.app/profile/#{client.session.handle}/post/#{bluesky_id}"

    post.syndication_links.create!(platform: "bluesky", url: url)
  ensure
    client.sign_out!
  end

  private

  def client
    @client ||= ATProto::Client.new(
      identifier: Rails.application.credentials.dig(:at_proto, :identifier),
      password: Rails.application.credentials.dig(:at_proto, :app_password)
    )
  end
end