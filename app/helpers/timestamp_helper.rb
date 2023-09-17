module TimestampHelper
  def timestamp(time, full: false, classes: [])
    text = if time < 1.day.ago
      format = "%b %-d"
      format += ", %Y" if time.year < Time.now.year

      time.strftime(format)
    else
      time_ago_in_words(time) + " ago"
    end

    # I stole this from a code golfing exercise 😬 It uses unicode hackery to
    # generate a clock emoji from a date object.
    if full
      d = ((time.to_i + time.gmtoff) / 900 - 3) / 2 % 24
      emoji = "" << 128336 + d / 2 + d % 2 * 12
      text = "#{emoji} #{text}"
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
