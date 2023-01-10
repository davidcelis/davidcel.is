ActiveRecord::Base.record_timestamps = false

file = ActiveSupport::EncryptedFile.new(
  content_path: Rails.root.join("db", "seeds", "notes", "tweets.json.enc"),
  key_path: Rails.root.join("config", "master.key"),
  env_key: "RAILS_MASTER_KEY",
  raise_if_missing_key: true
)

tweets = JSON.parse(file.read)
tweets.each do |tweet|
  # Skip replies and retweets for now.
  next if tweet["in_reply_to_status_id"]
  next if tweet["full_text"].match?(/^RT @\w+:/)

  # Skip anything with media for now.
  next if tweet.dig("extended_entities", "media").present?

  note = Note.find_or_initialize_by(id: tweet["id"].to_i)
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

  # Replace entities in reverse order so that indices don't change.
  entities.sort_by { |e| e[:range].first }.reverse_each do |e|
    text[e[:range]] = e[:replacement]
  end

  # Also parse and linkify Mastodon mentions
  text.gsub!(/@(\w+)@([a-z0-9.-]+)/) do |match|
    next match if $2 == "twitter.com"

    "[@#{$1}@#{$2}](https://#{$2}/@#{$1})"
  end

  note.content = text

  note.save!

  if note.previous_changes.any?
    puts "Updated Note: #{note.id} (#{note.slug})"
  end
end

ActiveRecord::Base.record_timestamps = true
