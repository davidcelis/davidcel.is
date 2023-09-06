module TimestampHelper
  def timestamp(time, full: false, classes: [])
    text = if time < 1.day.ago
      format = "%b %-d"
      format += ", %Y" if time.year < Time.now.year

      time.strftime(format)
    else
      time_ago_in_words(time) + " ago"
    end

    classes += %w[font-mono text-sm]
    options = {
      title: time.strftime("%-I:%M %p %Z • %b %-d, %Y"),
      class: classes,
      data: {"local-time-target" => "time"}
    }

    options[:data]["local-time-full"] = true if full

    time_tag(time, text, options)
  end
end
