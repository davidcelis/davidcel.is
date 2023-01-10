module TimestampHelper
  def timestamp(post, full: false)
    text = if post.created_at < 1.day.ago
      format = "%b %-d"
      format += ", %Y" if post.created_at.year < Time.now.year

      post.created_at.strftime(format)
    else
      time_ago_in_words(post.created_at) + " ago"
    end

    options = {
      title: post.created_at.strftime("%-I:%M %p %Z • %b %-d, %Y"),
      class: "font-mono text-sm leading-7",
      data: {"local-time-target" => "time"},
      pubdate: true
    }

    options[:data]["local-time-full"] = true if full

    time_tag post.created_at, text, options
  end
end
