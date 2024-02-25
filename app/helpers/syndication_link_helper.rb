module SyndicationLinkHelper
  # I also saved syndication links for posts I imported from Twitter and Swarm,
  # but these are the only two platforms I care about showing right now.
  EMOJI = {
    "bluesky" => "🦋",
    "mastodon" => "🦣"
  }.freeze

  def syndication_link_tag(link)
    return unless EMOJI.key?(link.platform)

    emoji = EMOJI[link.platform]
    label = "View on #{link.platform.titleize}"

    link_to(emoji, link.url, target: "_blank", rel: "noopener noreferrer", title: label, aria: {label: label})
  end
end
