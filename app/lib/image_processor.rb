class ImageProcessor
  def self.process(blob, size_limit: nil, pixel_limit: nil)
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

    quality = 100
    result = blob

    while File.size(result.path) > size_limit
      # It might seem silly to start at 99% and work our way down by single
      # digits, but often even the first pass at 99% will result in a much
      # smaller size. This lets us post high quality images with, hopefully,
      # only a few passes of compression.
      quality -= 1

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
