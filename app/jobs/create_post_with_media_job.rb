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
      elsif place_params.present?
        Place.find_or_create_by(place_params)
      end

      # For Link posts, we want to be able to show a preview card for the link.
      # To do that, we'll fetch relevant links from the post's `link_data` and
      # store them as MediaAttachments on the post.
      cache_link_images(post) if post.is_a?(Link)

      media_attachments_params.each do |blob_params|
        blob_params = blob_params.with_indifferent_access
        post.media_attachments.new(
          file: blob_params[:signed_id],
          description: blob_params.fetch(:description, "").strip.presence,
          featured: blob_params[:featured]
        )
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
end
