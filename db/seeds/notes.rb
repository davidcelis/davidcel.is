CDN_URL = "https://davidcelis-test.sfo3.cdn.digitaloceanspaces.com".freeze

ActiveRecord::Base.record_timestamps = false

resp = HTTParty.get("#{CDN_URL}/twitter_circle_tweets.json.enc")

tempfile = Tempfile.new
tempfile.binmode
tempfile.write(resp.body)
tempfile.rewind

file = ActiveSupport::EncryptedFile.new(
  content_path: tempfile.path,
  key_path: Rails.root.join("config", "master.key"),
  env_key: "RAILS_MASTER_KEY",
  raise_if_missing_key: true
)
twitter_circle_tweets = JSON.parse(file.read)
twitter_circle_tweet_ids = twitter_circle_tweets.map { |t| t["id"].to_i }

tweets = HTTParty.get("#{CDN_URL}/tweets.json")
tweets.each do |tweet|
  tweet_id = tweet["id"].to_i

  # Absolutely do not import tweets that I posted to my Twitter Circle. And for
  # any that might accidentally exist in the database, make sure to delete them.
  if twitter_circle_tweet_ids.include?(tweet_id)
    if (note = Note.find_by(id: tweet_id))
      note.destroy!
      puts "Deleted Note: #{note.id} (#{note.slug})"
    else
      puts "Skipping Note: #{tweet_id} (Circle)"
    end

    next
  end

  # Skip replies and retweets for now.
  next if tweet["in_reply_to_status_id"]
  next if tweet["full_text"].match?(/^RT @\w+:/)

  # Skip anything with media for now.
  # next if tweet.dig("extended_entities", "media").present?

  note = Note.find_or_initialize_by(id: tweet_id.to_i)
  note.created_at = note.updated_at = Time.parse(tweet["created_at"])

  # Parse the original tweet's text and auto-link stuff.
  text = tweet["full_text"]

  # Group and transform entities based on their indices so we can replace them
  # in reverse order; this lets us use the indices for replacement and avoid
  # clobbering due to out-of-order replacement causing indices to change.
  entities = []

  Array(tweet.dig("entities", "user_mentions")).each do |h|
    entities << {range: Range.new(*h["indices"].map(&:to_i), true), replacement: "[@#{h["screen_name"]}@twitter.com](https://twitter.com/#{h["screen_name"]})"}
  end

  Array(tweet.dig("entities", "urls")).each do |h|
    entities << {range: Range.new(*h["indices"].map(&:to_i), true), replacement: "[#{h["display_url"]}](#{h["expanded_url"]})"}
  end

  Array(tweet.dig("entities", "hashtags")).each do |h|
    entities << {range: Range.new(*h["indices"].map(&:to_i), true), replacement: "[##{h["text"]}](https://twitter.com/hashtag/#{h["text"]})"}
  end

  Array(tweet.dig("entities", "symbols")).each do |h|
    entities << {range: Range.new(*h["indices"].map(&:to_i), true), replacement: "[##{h["text"]}](https://twitter.com/search?q=%24#{h["text"]})"}
  end

  # Remove media URLs since we'll be adding them as attachments instead of text.
  Array(tweet.dig("entities", "media")).each do |h|
    entities << {range: Range.new(*h["indices"].map(&:to_i), true), replacement: ""}
  end

  # Replace entities in reverse order so that indices don't change.
  entities.sort_by { |e| e[:range].first }.reverse_each do |e|
    text[e[:range]] = e[:replacement]
  end

  # Also parse and linkify Mastodon mentions
  text.gsub!(/@(\w+)@([a-z0-9.-]+)/) do |match|
    next match if $2 == "twitter.com"

    "[@#{$1}@#{$2}](https://#{$2}/@#{$1})"
  end

  note.content = text.strip

  ActiveRecord::Base.transaction do
    Array(tweet.dig("extended_entities", "media")).each do |media|
      media_attachment = note.media_attachments.find_or_initialize_by(id: media["id"].to_i)
      next if media_attachment.file.attached?

      # Grab the file from our seed data in DigitalOcean and attach it.
      file_url = if media.dig("video_info", "variants").present?
        variant = media["video_info"]["variants"].max_by { |v| v["bitrate"].to_i }

        File.join(CDN_URL, "tweets_media", "#{note.id}-#{File.basename(variant["url"]).sub(/\?.*$/, "")}")
      else
        File.join(CDN_URL, "tweets_media", "#{note.id}-#{File.basename(media["media_url"])}")
      end

      response = HTTParty.get(file_url)
      raise "Error downloading #{file_url}: #{response.code}" if response.code >= 400

      filename = "#{media_attachment.id}#{File.extname(file_url)}"
      media_attachment.file.attach(key: "blog/#{filename}", io: StringIO.new(response.body), filename: filename)
      media_attachment.created_at = media_attachment.updated_at = note.created_at
      media_attachment.save!
    end

    note.save!
  end

  if note.previous_changes.any?
    puts "Updated Note: #{note.id} (#{note.slug})"
  end
end

ActiveRecord::Base.record_timestamps = true
