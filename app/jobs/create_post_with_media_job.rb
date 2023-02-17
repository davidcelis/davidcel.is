class CreatePostWithMediaJob < ApplicationJob
  def perform(post_params, media_attachments_params)
    ActiveRecord::Base.transaction do
      post = Post.new(post_params.with_indifferent_access)

      # Skip the content validation; posts with media can be blank.
      post.save(validate: false)

      media_attachments_params.each do |blob_params|
        blob_params = blob_params.with_indifferent_access
        media_attachment = post.media_attachments.create!(
          file: blob_params[:signed_id],
          description: blob_params.fetch(:description, "").strip.presence
        )

        content_type = media_attachment.file.content_type

        # If the file is a video, but not a web-friendly format, convert it to mp4.
        # Likewise, convert GIFs to mp4 to save on space.
        if content_type == "image/gif" || (content_type.start_with?("video/") && content_type != "video/mp4")
          convert_to_mp4(media_attachment, original_content_type: content_type)
        end

        # If the file is a video, generate and immediately attach a preview image.
        generate_preview_image(media_attachment) if media_attachment.file.video?
      end

      post.save!
    end
  end

  private

  def convert_to_mp4(media_attachment, original_content_type:)
    filename = media_attachment.file.blob.filename.to_s

    Tempfile.open([filename, ".mp4"], binmode: true) do |tempfile|
      media_attachment.file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-movflags", "faststart", "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", tempfile.path, exception: true)
      end
      tempfile.rewind

      filename = "#{media_attachment.id}.mp4"
      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{filename}",
        io: tempfile.to_io,
        filename: filename,
        metadata: {custom: {original_content_type: original_content_type}}
      )

      media_attachment.file.attach(blob)
    end
  end

  def generate_preview_image(media_attachment)
    filename = media_attachment.file.blob.filename.to_s

    Tempfile.open([filename, ".jpg"], binmode: true) do |tempfile|
      media_attachment.file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-vf", "select=eq(n\\,0)", "-q:v", "3", tempfile.path, exception: true)
      end
      tempfile.rewind

      filename = "#{media_attachment.id}.jpg"
      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/previews/#{filename}",
        io: tempfile.to_io,
        filename: filename
      )

      media_attachment.preview_image.attach(blob)
    end
  end

  def ffmpeg
    @ffmpeg ||= ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
  end
end
