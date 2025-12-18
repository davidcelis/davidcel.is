class ImageProcessor
  def self.process(blob, size_limit: nil, pixel_limit: nil, quality_interval: 1, convert_to: nil)
    return blob unless size_limit.present? || pixel_limit.present?

    # First, resize the image if it exceeds the given pixel limit; we'll
    # calculate the ratio of the image's width to height and then resize it to
    # fit the total pixel limit.
    image = Vips::Image.new_from_file(blob.path)

    width, height = [image.width, image.height]
    if pixel_limit.present? && (width * height) > pixel_limit
      ratio = Math.sqrt(pixel_limit / (width * height).to_f)
      new_width, new_height = [width, height].map(&ratio.method(:*))

      blob = ImageProcessing::Vips
        .source(blob.path)
        .resize_to_limit(new_width, new_height)
        .call
    end

    # Next, convert the image to the desired format if one is specified and if
    # the image exceeds the size limit. This is mostly due to the difficulty in
    # compressing certain formats like PNG as well as the very low size limits
    # imposed by Bluesky. For those reasons, converting to JPEG is often best.
    if convert_to.present? && File.size(blob.path) > size_limit
      blob = ImageProcessing::Vips.source(blob.path).convert!(convert_to)
    end

    quality = 100
    result = blob

    while File.size(result.path) > size_limit
      quality -= quality_interval

      result = ImageProcessing::Vips
        .source(blob.path)
        .saver(Q: quality, optimize_coding: true)
        .call

      mb = File.size(result.path) / 1e6
      puts "Compressed image to #{mb} MB at #{quality}% quality."
    end

    result
  end
end
