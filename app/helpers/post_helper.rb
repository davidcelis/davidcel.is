module PostHelper
  EMOJI = {
    "Article" => "📝",
    "Note" => "✏️",
    "Link" => "🔗",
    "CheckIn" => "📍"
  }.freeze

  def post_emoji(post)
    EMOJI[post.type]
  end
end
