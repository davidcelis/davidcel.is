# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.record_timestamps = false

CDN_URL = "https://davidcelis-test.sfo3.cdn.digitaloceanspaces.com".freeze
FFMPEG = ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path

instagram_posts = HTTParty.get("#{CDN_URL}/instagram_posts.json")
instagram_posts.each do |post|
  ActiveRecord::Base.transaction do
    note = Note.new(content: post["title"] || post.dig("media", 0, "title"))
    note.created_at = note.updated_at = Time.at(post.dig("media", 0, "creation_timestamp"))
    note.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{note.created_at}')")

    begin
      note.save(validate: false)
    rescue ActiveRecord::RecordNotUnique
      puts "Skipping duplicate post: #{note.content}"
      next
    end

    post["media"].each do |media|
      media_attachment = note.media_attachments.new
      media_attachment.created_at = media_attachment.updated_at = note.created_at
      media_attachment.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{note.created_at}')")

      file_url = media["uri"].sub("media/posts", "#{CDN_URL}/instagram_posts")
      response = HTTParty.get(file_url)
      raise "Error downloading #{file_url}: #{response.code}" if response.code >= 400

      file_extension = File.extname(file_url)
      filename = "#{media_attachment.id}#{file_extension}"

      Tempfile.open([filename, file_extension], binmode: true) do |file|
        file.write(response.body)
        file.rewind

        media_attachment.file.attach(
          key: "blog/#{filename}",
          io: File.open(file.path),
          filename: filename
        )

        if media_attachment.file.video?
          file.rewind

          filename = media_attachment.file.blob.filename.to_s

          Tempfile.open([filename, ".jpg"], binmode: true) do |tempfile|
            system(FFMPEG, "-y", "-i", file.path, "-vf", "thumbnail", "-frames:v", "1", tempfile.path, exception: true)
            tempfile.rewind

            filename = "#{media_attachment.id}.jpg"
            blob = ActiveStorage::Blob.create_and_upload!(
              key: "blog/previews/#{filename}",
              io: File.open(tempfile.path),
              filename: filename
            )

            media_attachment.preview_image.attach(blob)
          end
        end

        media_attachment.save!
      end
    end
  end
end

ActiveRecord::Base.record_timestamps = true
