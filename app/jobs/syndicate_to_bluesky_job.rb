class SyndicateToBlueskyJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::SanitizeHelper

  BLUESKY_POST_URL_REGEX = %r{https://bsky.app/profile/(?<repo>[^/]+)/post/(?<rkey>[^/]+)}

  def perform(post_id)
    post = Post.find(post_id)

    # Although ATProto technically supports updating repo records, Bluesky
    # has "temporarily" disabled this for posts. Until they support editing
    # posts, we'll delete the original record and create a new one.
    if (link = post.syndication_links.find_by(platform: "bluesky"))
      rkey = link.url.split("/").last
      client.delete_post(rkey)
      link.destroy!
    end

    # If the post is an Article, we'll syndicate the excerpt and URL.
    if post.is_a?(Article) && !post.syndication_links.where(platform: "bluesky").exists?
      text = (post.og_description.presence || post.title).truncate(300)
      embed = {
        "$type" => "app.bsky.embed.external",
        "external" => {
          "uri" => article_url(post),
          "title" => post.title,
          "description" => post.og_description
        }
      }

      if (image = post.media_attachments.find(&:image?))
        unless image.webp_variant_attachment.analyzed?
          logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
          return SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
        end

        blob_result = client.upload_blob(image.webp_variant_attachment)
        embed["external"]["thumb"] = blob_result["blob"]
      end

      response = client.create_post(text: text, created_at: post.created_at, embed: embed)
      return create_syndication_link(post, response)
    end

    images = post.media_attachments.select(&:image?)
    unless images.all? { |image| image.webp_variant_attachment.analyzed? }
      logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
      SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
      return
    end

    embed = nil
    text = case post
    when Note
      content = post.content

      # If the content is longer than 300 characters, we'll truncate it and
      # append a link to the full post.
      if character_count(content) > 300
        url = polymorphic_url(post)

        # Truncate the content so that it and the URL (23 characters),
        # separated by an ellipsis and a space, fit within the 300 character
        # limit.
        content = content.truncate(300 - 25, omission: "")
        content << "… #{url}"
      end

      content
    when Link
      content = post.content

      # If the link is to a Bluesky post, we'll embed the link as a quote post.
      # Otherwise, we'll embed it as an external link.
      if character_count(content) <= 300 && (match = BLUESKY_POST_URL_REGEX.match(post.link_data["url"]))
        record = client.get_post(repo: match[:repo], collection: "app.bsky.feed.post", rkey: match[:rkey])

        embed = {"$type" => "app.bsky.embed.record", "record" => {"uri" => record["uri"], "cid" => record["cid"]}}
      else
        embed = {"$type" => "app.bsky.embed.external", "external" => {}}

        if character_count(content) > 300
          content = "🔗 #{post.title}"

          embed["external"]["uri"] = polymorphic_url(post)
          embed["external"]["title"] = "🔗 #{post.title}"
          embed["external"]["description"] = strip_tags(post.excerpt).squish
        else
          embed["external"]["uri"] = post.link_data["url"]
          embed["external"]["title"] = post.link_data.dig("meta", "title")

          if (description = post.link_data.dig("meta", "description"))
            embed["external"]["description"] = description
          end
        end

        if post.preview_image.attached?
          blob_result = client.upload_blob(post.preview_image_attachment)

          embed["external"]["thumb"] = blob_result["blob"]
        end
      end

      content
    when CheckIn
      content = post.content.presence

      pin = content ? "📍" : "📍I checked in at "
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
      result = client.upload_blob(media_attachment.webp_variant_attachment)

      {
        image: result["blob"],
        alt: media_attachment.description,
        aspectRatio: {
          width: media_attachment.width,
          height: media_attachment.height
        }
      }
    end

    if (video = post.media_attachments.find(&:video?))
      unless video.analyzed?
        logger.info("Media attachments are still being analyzed; trying again in 5 seconds...")
        SyndicateToBlueskyJob.perform_in(5.seconds, post_id)
        return
      end

      result = client.upload_video(video)

      embed = {
        "$type" => "app.bsky.embed.video",
        "video" => result,
        "alt" => video.description,
        "aspectRatio" => {
          "width" => video.width,
          "height" => video.height
        }
      }
    end

    if (link = post.syndication_links.find_by(platform: "bluesky"))
      rkey = link.url.split("/").last
      client.update_post(rkey, text: text, created_at: post.created_at, facets: facets, images: blobs, embed: embed)
    else
      response = client.create_post(text: text, created_at: post.created_at, facets: facets, images: blobs, embed: embed)
      create_syndication_link(post, response)
    end
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
