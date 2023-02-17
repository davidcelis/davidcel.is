class MediaAttachment < ApplicationRecord
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

  default_scope { order(id: :asc) }

  def width
    metadata[:width]
  end

  def height
    metadata[:height]
  end

  def gif?
    custom_metadata[:original_content_type] == "image/gif"
  end

  def video?
    return false if gif?

    file.video?
  end

  def video_or_gif?
    video? || gif?
  end
end
