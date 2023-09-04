class CreatePostWithMediaJob < ApplicationJob
  def perform(post_params, media_attachments_params, place_params)
    post_params = post_params.with_indifferent_access
    place_params = place_params.with_indifferent_access.compact_blank

    post_params[:type] = "CheckIn" if place_params.any?

    ActiveRecord::Base.transaction do
      post = Post.new(post_params)

      if post.is_a?(CheckIn)
        # We'll find or create the place based on the UUID from Apple Maps.
        place = Place.find_or_initialize_by(apple_maps_id: place_params[:apple_maps_id])
        place.coordinates = [place_params.delete(:longitude), place_params.delete(:latitude)]
        place.update!(place_params)

        # Assign the place and save the post so it has an ID that we can use.
        post.place = place
        post.save

        # Then, for the check-in itself, we'll generate a snapshot of the map
        # as it was at the time of the check-in. If the place moves later, the
        # snapshot keeps the historical context of where I actually was.
        snapshot = Apple::MapKit::Snapshot.new(point: [place.latitude, place.longitude].join(","))
        response = HTTParty.get(snapshot.url)

        file_extension = Rack::Mime::MIME_TYPES.invert["image/png"]
        filename = "#{post.id}#{file_extension}"

        Tempfile.open([filename, file_extension], binmode: true) do |file|
          file.write(response.body)
          file.rewind

          post.snapshot.attach(
            key: "blog/#{filename}",
            io: File.open(file.path),
            filename: filename
          )
        end

        # Finally, we'll use the WeatherKit API to get the current weather.
        begin
          response = Apple::WeatherKit::CurrentWeather.at(latitude: place.latitude, longitude: place.longitude)
          post.weather = response["currentWeather"]
        rescue HTTParty::Error
          # No sweat. We'll just skip the weather if Apple's API is down.
        end
      end

      # One last thing for check-ins: their slug is supposed to contain both
      # the place's name _and_ the check-in's ID, so we'll need to regenerate
      # the slug now that we have the ID.
      post.send(:generate_slug) if post.is_a?(CheckIn)
      post.save

      media_attachments_params.each do |blob_params|
        blob_params = blob_params.with_indifferent_access
        media_attachment = post.media_attachments.create!(
          file: blob_params[:signed_id],
          description: blob_params.fetch(:description, "").strip.presence
        )

        # If the file is a video, but not a web-friendly format, convert it to mp4.
        # Likewise, convert GIFs to mp4 to save on space.
        if media_attachment.gif? || (media_attachment.video? && media_attachment.file.content_type != "video/mp4")
          convert_to_mp4(media_attachment, original_content_type: media_attachment.file.content_type)
        end

        # If the file is a video, generate and immediately attach a preview image.
        generate_preview_image(media_attachment) if media_attachment.file.video?

        # I've noticed really funky stuff happening with images that have EXIF
        # orientation data. Uploaded images have been appearing normal in almost
        # every location, but in very specific circumstances, the rotation seems
        # to get repeated. The two places I've noticed this so far are iMessage
        # link previews and RSS feed previews (specifically Reeder). When the
        # image is embedded in HTML, it renders correctly, but when rendered
        # independently of the HTML, it's re-rotated and looks wrong. To avoid
        # this, we'll just manually rotate the image to the correct orientation
        # and then strip the orientation EXIF data.
        rotate_image(media_attachment) if media_attachment.file.image?
      end

      post.save!
    end
  end

  private

  def convert_to_mp4(media_attachment, original_content_type:)
    filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")

    Tempfile.open([filename, ".mp4"], binmode: true) do |tempfile|
      media_attachment.file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-movflags", "faststart", "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", tempfile.path, exception: true)
      end
      tempfile.rewind

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{media_attachment.id}.mp4",
        io: tempfile.to_io,
        filename: "#{filename}.mp4",
        metadata: {custom: {original_content_type: original_content_type}}
      )

      media_attachment.file.attach(blob)
    end
  end

  def generate_preview_image(media_attachment)
    filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")

    Tempfile.open([filename, ".jpg"], binmode: true) do |tempfile|
      media_attachment.file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-vf", "select=eq(n\\,0)", "-q:v", "3", tempfile.path, exception: true)
      end
      tempfile.rewind

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/previews/#{media_attachment.id}.jpg",
        io: tempfile.to_io,
        filename: "#{filename}.jpg"
      )

      media_attachment.preview_image.attach(blob)
    end
  end

  def rotate_image(media_attachment)
    filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")
    extension = Rack::Mime::MIME_TYPES.invert[media_attachment.content_type]

    Tempfile.open([filename, extension], binmode: true) do |tempfile|
      media_attachment.file.blob.open do |file|
        image = Vips::Image.new_from_file(file.path)
        image = image.autorot
        image.write_to_file(tempfile.path)
        tempfile.rewind
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{media_attachment.id}#{extension}",
        io: tempfile.to_io,
        filename: "#{filename}#{extension}"
      )

      media_attachment.file.attach(blob)
    end
  end

  def ffmpeg
    @ffmpeg ||= ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
  end
end
