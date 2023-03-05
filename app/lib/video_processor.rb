class VideoProcessor
  class_attribute :ffmpeg, default: ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path

  def self.process(blob, width:, height:, duration:, audio: false, size_limit: nil, pixel_limit: nil)
    result = downscale(blob, width: width, height: height, pixel_limit: pixel_limit)
    compress(result, duration: duration, audio: audio, size_limit: size_limit)
  end

  def self.downscale(blob, width:, height:, pixel_limit: nil)
    result = blob
    return result unless pixel_limit.present?

    # Downscale the video if it exceeds the given pixel limit. For example,
    # Mastodon's limit of 2,304,000 pixels is roughly 1920x1200 either way.
    if width * height > pixel_limit
      result = Tempfile.new(["video", ".mp4"])

      # Get the aspect ratio of the video and use it to calculate the new
      # dimensions, making sure that each dimension is divisible by 2.
      aspect_ratio = width.to_f / height
      new_width = (Math.sqrt(pixel_limit * aspect_ratio) / 2).floor * 2
      new_height = (Math.sqrt(pixel_limit / aspect_ratio) / 2).floor * 2

      system(ffmpeg, "-y", "-i", blob.path, "-vf", "scale=#{new_width}:#{new_height}", result.path)
    end

    result
  end

  def self.compress(blob, duration:, audio: false, size_limit: nil)
    result = blob
    return result unless size_limit.present?

    bitrate = (size_limit * 8000) / duration.to_f
    bitrate -= 128 if audio
    buffer = (bitrate * 0.05).floor

    while File.size(result.path) > size_limit.megabytes
      new_result = Tempfile.new(["video", ".mp4"])

      # We'll use the video's duration and given file size limit to determine
      # the target bitrate for two-pass compression, making sure to account for
      # a targeted audio bitrate of 128k.
      #
      # More info: https://trac.ffmpeg.org/wiki/Encode/H.264#twopass
      system(ffmpeg, "-y", "-i", result.path, "-c:v", "libx264", "-b:v", "#{bitrate}k", "-pass", "1", "-an", "-f", "mp4", "/dev/null")
      system(ffmpeg, "-y", "-i", result.path, "-c:v", "libx264", "-b:v", "#{bitrate}k", "-pass", "2", "-c:a", "aac", "-b:a", "128k", new_result.path)
      new_result.rewind

      result = new_result

      # Reduce the bitrate by 5% before trying again.
      bitrate -= buffer
    end

    result
  end
end
