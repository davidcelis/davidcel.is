class ImageProcessor
  def self.process(blob, size_limit: nil)
    result = blob
    return result unless size_limit.present?

    result = blob
    quality = 100

    while File.size(result.path) > size_limit
      # It might seem silly to start at 99% and work our way down by single
      # digits, but often even the first pass at 99% will result in a much
      # smaller size. This lets us post high quality images with, hopefully,
      # only a few passes of compression.
      quality -= 1

      result = ImageProcessing::Vips
        .source(blob.path)
        .saver(Q: quality, optimize_coding: true, trellis_quant: true)
        .call
    end

    result
  end
end
