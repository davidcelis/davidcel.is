CDN_URL = "https://davidcelis-test.sfo3.cdn.digitaloceanspaces.com".freeze

ActiveRecord::Base.record_timestamps = false

outbox = HTTParty.get("#{CDN_URL}/toots.json")
outbox["orderedItems"].each do |activity|
  # Skip anything that isn't public
  next unless activity["to"].include?("https://www.w3.org/ns/activitystreams#Public")

  toot = activity["object"]

  # Skip replies and boosts for now.
  next if toot["inReplyTo"].present?
  next if activity["type"] == "Announce"

  # Convert the toot's content from HTML back to Markdown.
  content = ReverseMarkdown.convert(toot["content"]).delete("\\").strip

  # Parse the content with CommonMarker to get an AST so we can convert links
  # back to plain text mentions/hashtags/URLs.
  doc = CommonMarker.render_doc(content, :UNSAFE)
  doc.walk do |node|
    next unless node.type == :link

    # If the link is a mention, convert it to plaintext (@username@example.com)
    uri = URI.parse(node.url)
    if (match = uri.path.match(/\A\/@([a-z0-9_]+)\z/))
      text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = "@#{match[1]}@#{uri.host}" }
      node.insert_before(text_node)
    elsif uri.host == "xoxo.zone" && uri.path.start_with?("/media/")
      # If the link is a media attachment, don't replace it with anything. The
      # attachment data is already stored elsewhere in the archive.
    else
      # Otherwise, convert it to plaintext (https://example.com)
      text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = node.url }
      node.insert_before(text_node)
    end

    node.delete
  end

  content = doc.to_commonmark(:UNSAFE, 1000).strip.delete("\\")

  note = Note.find_or_initialize_by(content: content)
  ActiveRecord::Base.transaction do
    if note.new_record?
      note.created_at = note.updated_at = Time.parse(activity["published"])
      note.id ||= ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{note.created_at}')")

      puts "Creating Note #{note.id} from Toot: #{toot["url"]}"

      toot["attachment"].each do |attachment|
        media_attachment = note.media_attachments.new(
          id: ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{note.created_at}')"),
          description: attachment["name"],
          created_at: note.created_at,
          updated_at: note.created_at
        )

        file_url = "#{CDN_URL}#{attachment["url"]}"

        response = HTTParty.get(file_url)
        raise "Error downloading #{file_url}: #{response.code}" if response.code >= 400

        file_extension = File.extname(file_url)
        filename = "#{media_attachment.id}#{file_extension}"

        media_attachment.file.attach(
          key: "blog/#{filename}",
          io: StringIO.new(response.body),
          filename: filename
        )

        media_attachment.save!
      end
    else
      puts "Found existing Note #{note.id} for Toot: #{toot["url"]}"
    end

    mastodon_link = note.syndication_links.find_or_initialize_by(
      platform: "mastodon",
      url: toot["url"]
    )
    mastodon_link.created_at = mastodon_link.updated_at = note.created_at
    mastodon_link.save!

    note.save!
  end

  if note.previous_changes.any?
    puts "Updated Note: #{note.id} (#{note.slug})"
  end
end

ActiveRecord::Base.record_timestamps = true
