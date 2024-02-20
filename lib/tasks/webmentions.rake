namespace :webmentions do
  desc "Assign the correct type to existing webmentions"
  task backfill_types: [:environment] do
    Webmention.verified.find_each do |webmention|
      mf2 = Microformats::Collection.new(webmention.mf2)

      h_entry = mf2.items.find { |item| item.type == "h-entry" }
      emoji = nil

      if h_entry.respond_to?(:like_of)
        webmention.type = "like"
        emoji = "❤️ "
      elsif h_entry.respond_to?(:repost_of)
        webmention.type = "repost"
        emoji = "🔁"
      elsif h_entry.respond_to?(:in_reply_to)
        webmention.type = "reply"
        emoji = "💬"
      else
        webmention.type = "mention"
        emoji = "🔗"
      end

      webmention.save!

      puts [emoji, webmention.id].join(" ")
    end
  end
end
