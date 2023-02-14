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
  after_commit :generate_preview_image, on: [:create], if: :video?

  default_scope { order(id: :asc) }

  def width
    dimensions.first
  end

  def height
    dimensions.last
  end

  def dimensions
    @dimensions ||= if (video? || gif?) && preview_image.attached?
      [preview_image.metadata[:width], preview_image.metadata[:height]]
    else
      [metadata[:width], metadata[:height]]
    end
  end

  def gif?
    custom_metadata[:original_content_type] == "image/gif"
  end

  def video?
    return false if gif?

    file.video?
  end

  private

  def generate_preview_image
    return if preview_image.attached?

    GeneratePreviewImageJob.perform_async(id)
  end
end
