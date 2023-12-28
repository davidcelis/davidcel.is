class MediaAttachment < ApplicationRecord
  DEFAULT_INCLUDES = [
    :post,
    {
      file_attachment: :blob,
      webp_variant_attachment: :blob,
      preview_image_attachment: :blob
    }
  ].freeze

  include SnowflakeID

  belongs_to :post

  has_one_attached :file
  delegate_missing_to :file

  # There's no easy way to store ActiveStorage previews or variants in a reasonable
  # file structure when using an S3-compatible service; Rails sticks them all in the
  # root of the bucket, which is really messy. The easy way around this is to generate
  # and attach them as a separate file.
  #
  # To keep things simple for now, I'm only generating preview images for videos, but
  # I may eventually use it to store smaller thumbnails for regular images as well.
  has_one_attached :preview_image
  has_one_attached :webp_variant

  default_scope { order(id: :asc) }

  scope :featured, -> { where(featured: true) }

  after_create :convert_to_mp4!, if: -> { gif? || (video? && content_type != "video/mp4") }
  after_create :generate_preview_image!, if: :video_or_gif?
  after_create :convert_from_heic!, if: -> { content_type == "image/heic" }
  after_create :rotate!, if: :image?
  after_create :generate_webp_variant!, if: :image?

  def width
    metadata[:width]
  end

  def height
    metadata[:height]
  end

  def gif?
    content_type == "image/gif" || custom_metadata[:original_content_type] == "image/gif"
  end

  def video?
    return false if gif?

    file.video?
  end

  def video_or_gif?
    video? || gif?
  end

  private

  def convert_to_mp4!
    filename = File.basename(file.blob.filename.to_s, ".*")
    original_content_type = file.content_type

    Tempfile.open([filename, ".mp4"], binmode: true) do |tempfile|
      file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-movflags", "faststart", "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", tempfile.path, exception: true)
      end
      tempfile.rewind

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{id}.mp4",
        io: tempfile.to_io,
        filename: "#{filename}.mp4",
        metadata: {custom: {original_content_type: original_content_type}}
      )

      blob.analyze
      file.attach(blob)
    end
  end

  def generate_preview_image!
    filename = File.basename(file.blob.filename.to_s, ".*")

    Tempfile.open([filename, ".jpg"], binmode: true) do |tempfile|
      file.blob.open do |file|
        system(ffmpeg, "-y", "-i", file.path, "-vf", "select=eq(n\\,0)", "-q:v", "3", tempfile.path, exception: true)
      end
      tempfile.rewind

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/previews/#{id}.jpg",
        io: tempfile.to_io,
        filename: "#{filename}.jpg"
      )

      blob.analyze
      preview_image.attach(blob)
    end
  end

  def convert_from_heic!
    filename = File.basename(file.blob.filename.to_s, ".*")

    file.blob.open do |file|
      jpeg = ImageProcessing::Vips.source(file).convert("jpeg").call
      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{id}.jpeg",
        io: File.open(jpeg.path),
        filename: "#{filename}.jpeg"
      )

      blob.analyze
      file.attach(blob)
    end
  end

  def rotate!
    filename = File.basename(file.blob.filename.to_s, ".*")
    extension = Rack::Mime::MIME_TYPES.invert[content_type]

    Tempfile.open([filename, extension], binmode: true) do |tempfile|
      file.blob.open do |file|
        image = Vips::Image.new_from_file(file.path)
        image = image.autorot
        image.write_to_file(tempfile.path)
        tempfile.rewind
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{id}#{extension}",
        io: tempfile.to_io,
        filename: "#{filename}#{extension}"
      )

      blob.analyze
      file.attach(blob)
    end
  end

  def generate_webp_variant!
    # If the file is already a WebP, just attach it as the webp_variant.
    return webp_variant.attach(file.blob) if content_type == "image/webp"

    filename = File.basename(file.blob.filename.to_s, ".*")

    file.blob.open do |file|
      webp = ImageProcessing::Vips.source(file).convert("webp").call
      blob = ActiveStorage::Blob.create_and_upload!(
        key: "blog/#{id}.webp",
        io: webp.to_io,
        filename: "#{filename}.webp"
      )

      blob.analyze
      webp_variant.attach(blob)
    end
  end

  def ffmpeg
    @ffmpeg ||= ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
  end
end
