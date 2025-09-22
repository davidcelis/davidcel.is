module SyndicationLinkHelper
  # I also saved syndication links for posts I imported from Twitter and Swarm,
  # but these are the only two platforms I care about showing right now.
  EMOJI = {
    "bluesky" => "🦋",
    "mastodon" => "🦣",
    "threads" => "🧵"
  }.freeze

  def syndication_link_emoji(link)
    EMOJI[link.platform]
  end

  def syndication_link_tag(link, webmentions: [])
    emoji = tag.span("#{syndication_link_emoji(link)} ", class: ["font-sans", "select-none"], aria: {hidden: true})
    link = link_to link.platform.titleize, link.url, target: "_blank", rel: "noopener noreferrer", class: ["link-primary", "font-bold"]
    divider = tag.span(" / ", class: "select-none", aria: {hidden: true})

    reply_count = if (replies = webmentions.select(&:reply?).presence)
      divider + tag.span("💬 #{replies.count}", title: "Replies", aria: {label: "Replies"})
    end

    repost_count = if (reposts = webmentions.select(&:repost?).presence)
      divider + tag.span("🔁 #{reposts.count}", title: "Reposts", aria: {label: "Reposts"})
    end

    like_count = if (likes = webmentions.select(&:like?).presence)
      divider + tag.span("❤️ #{likes.count}", title: "Likes", aria: {label: "Likes"})
    end

    emoji + link + (reply_count || "") + (repost_count || "") + (like_count || "")
  end
end
