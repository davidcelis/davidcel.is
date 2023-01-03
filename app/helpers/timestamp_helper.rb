module TimestampHelper
  def timestamp(post)
    text = if post.created_at < 1.day.ago
      format = "%b %-d"
      format += ", %Y" if post.created_at.year < Time.now.year

      post.created_at.strftime(format)
    else
      time_ago_in_words(post.created_at) + " ago"
    end

    time_tag post.created_at, text, title: post.created_at.strftime("%-I:%M %p %Z • %b %-d, %Y"), class: "font-mono text-sm leading-7 text-slate-500", pubdate: true
  end
end
