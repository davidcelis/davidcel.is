class CreatePostWithMediaJob < ApplicationJob
  def perform(post_params, media_attachments_params, place_params)
    post_params = post_params.with_indifferent_access
    place_params = place_params.with_indifferent_access.compact_blank

    post_params[:type] = "CheckIn" if place_params.key?(:apple_maps_id)

    ActiveRecord::Base.transaction do
      # Because there are various parts of this complicated process that rely
      # on the post having an ID, we'll just initialize it here and pull an ID
      # before saving it.
      post = Post.new(post_params)
      post.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id();")

      # If we have coordinates, we'll use the WeatherKit API to get the weather
      Sentry.configure_scope do |scope|
        scope.set_context("params", {post: post_params.to_h, media_attachments: media_attachments_params.map(&:to_h), place: place_params.to_h})

        fetch_weather(post)
      end

      # If the post is a check-in, we'll create a specific Place for it. If
      # it's not a check-in, we'll still create a generic Place for the post's
      # coordinates but without any of the extra stuff like snapshots.
      post.place = if post.is_a?(CheckIn)
        create_check_in_place(post, place_params: place_params)
      else
        Place.find_or_create_by(place_params)
      end

      # For Link posts, we want to be able to show a preview card for the link.
      # To do that, we'll fetch relevant links from the post's `link_data` and
      # store them as MediaAttachments on the post.
      cache_link_images(post) if post.is_a?(Link)

      # Then, we'll save the post so that we can start attaching the media.
      # We have to skip validations here because posts with media attachments
      # are allowed to have no content. We'll save the post one last time with
      # validations at the very end of this process.
      post.save(validate: false)

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

        # If the file is an image that was uploaded from an iPhone, it's probably
        # in HEIC format, so we'll convert it to JPEG.
        convert_image(media_attachment) if media_attachment.content_type == "image/heic"

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

        # Finally, if we have an image, we'll generate a WebP variant of it too.
        generate_webp_variant(media_attachment) if media_attachment.file.image?
      end

      post.save!
    end
  end

  private

  def create_check_in_place(post, place_params:)
    # We'll find or create the place based on the UUID from Apple Maps.
    place = Place.find_or_initialize_by(apple_maps_id: place_params[:apple_maps_id])
    place.coordinates = [place_params.delete(:longitude), place_params.delete(:latitude)]
    place.update!(place_params)

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

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/snapshots/#{filename}",
        io: File.open(file.path),
        filename: filename
      )

      blob.analyze
      post.snapshot.attach(blob)

      # Generate a WebP variant of the snapshot to save on bandwidth.
      # We'll use the same filename as the original, but with a different
      # extension.
      webp = ImageProcessing::Vips
        .source(file)
        .convert("webp")
        .call

      webp_blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/snapshots/#{post.id}.webp",
        io: File.open(webp.path),
        filename: "#{post.id}.webp"
      )

      webp_blob.analyze
      post.webp_snapshot.attach(webp_blob)
    end

    place
  end

  def fetch_weather(post)
    latitude = post.place&.latitude || post.latitude
    longitude = post.place&.longitude || post.longitude

    return Sentry.capture_message("No coordinates") unless latitude.present? && longitude.present?

    response = Apple::WeatherKit::CurrentWeather.at(latitude: latitude, longitude: longitude)
    post.weather = response["currentWeather"]

    aqi = AQI.at(latitude: latitude, longitude: longitude)
    post.weather["airQualityIndex"] = aqi
  end

  def cache_link_images(post)
    if (favicon = post.link_data.dig("links", "icon", 0))
      extension = Rack::Mime::MIME_TYPES.invert[favicon["type"]]

      favicon_blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/links/#{post.id}/favicon#{extension}",
        io: URI.parse(favicon["href"]).open,
        filename: "favicon#{extension}"
      )

      favicon_blob.analyze
      post.favicon.attach(favicon_blob)
    end

    if (preview_image = post.link_data.dig("links", "thumbnail", 0))
      extension = Rack::Mime::MIME_TYPES.invert[preview_image["type"]]

      preview_image_blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/links/#{post.id}/preview#{extension}",
        io: URI.parse(preview_image["href"]).open,
        filename: "preview#{extension}"
      )

      preview_image_blob.analyze
      post.preview_image.attach(preview_image_blob)
    end
  end

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

      blob.analyze
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

      blob.analyze
      media_attachment.preview_image.attach(blob)
    end
  end

  def convert_image(media_attachment)
    filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")

    media_attachment.file.blob.open do |file|
      jpeg = ImageProcessing::Vips
        .source(file)
        .convert("jpeg")
        .call

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{media_attachment.id}.jpeg",
        io: File.open(jpeg.path),
        filename: "#{filename}.jpeg"
      )

      blob.analyze
      media_attachment.file.attach(blob)
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

      blob.analyze
      media_attachment.file.attach(blob)
    end
  end

  def generate_webp_variant(media_attachment)
    filename = File.basename(media_attachment.file.blob.filename.to_s, ".*")

    media_attachment.file.blob.open do |file|
      webp = ImageProcessing::Vips
        .source(file)
        .convert("webp")
        .call

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{media_attachment.id}.webp",
        io: webp.to_io,
        filename: "#{filename}.webp"
      )

      blob.analyze
      media_attachment.webp_variant.attach(blob)
    end
  end

  def ffmpeg
    @ffmpeg ||= ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
  end
end
