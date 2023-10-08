module MediaGalleryHelper
  def media_gallery_tag(media_attachments)
    gallery_length = media_attachments.length
    return if gallery_length == 0

    classes = %w[grid gap-x-1 gap-y-1 mt-4 overflow-hidden]
    classes << "grid-cols-2" if gallery_length >= 2

    data = {}
    unless media_attachments.all?(&:gif?)
      data["controller"] = "lightbox"
      data["lightbox-options-value"] = {
        video: media_attachments.any?(&:video?),
        counter: media_attachments.length > 1
      }.to_json
    end

    tag.div(class: classes, data: data) do
      media_attachments.map.with_index do |media_attachment, i|
        if media_attachment.image?
          media_gallery_image_tag(media_attachment, i: i, total: gallery_length)
        elsif media_attachment.gif?
          media_gallery_gif_tag(media_attachment, i: i, total: gallery_length)
        elsif media_attachment.video?
          media_gallery_video_tag(media_attachment, i: i, total: gallery_length)
        end
      end.join.html_safe
    end
  end

  private

  def media_gallery_image_tag(media_attachment, i:, total:)
    classes = ["relative"]
    classes << "row-span-2" if i == 0 && total == 3

    link_to cdn_file_url(media_attachment), class: classes do
      image_classes = %w[u-photo object-cover height-full w-full]
      image_classes += additional_classes_for(file: media_attachment, i: i, total: total)

      image_element = image_tag(cdn_file_url(media_attachment), loading: "lazy", alt: media_attachment.description, class: image_classes)

      image_element + alt_text_badge(media_attachment)
    end
  end

  def media_gallery_gif_tag(media_attachment, i:, total:)
    classes = %w[flex justify-center items-center cursor-pointer relative]
    classes << "row-span-2" if i == 0 && total == 3

    tag.div(class: classes, data: {controller: "play", action: "click->play#playOrPause"}) do
      video_classes = %w[u-video]
      video_classes += additional_classes_for(file: media_attachment, i: i, total: total)
      video_element = content_tag("video", media_attachment.description, src: cdn_file_url(media_attachment.file), poster: cdn_file_url(media_attachment.preview_image), preload: "none", playsinline: true, controls: false, loop: true, width: media_attachment.width, height: media_attachment.height, class: video_classes, data: {"play-target" => "item", "action" => "playOrPause"})

      alt_text_badge = alt_text_badge(media_attachment, fully_rounded: false)

      gif_badge = tag.div(class: "absolute left-2 bottom-2") do
        gif_badge_classes = %w[font-bold font-ui-sans rounded-l-[.25rem] bg-black bg-opacity-[.65] text-white hover:bg-black px-1 select-none]
        gif_badge_classes << "rounded-r-[.25rem]" if alt_text_badge.blank?

        tag.button("GIF", class: gif_badge_classes, data: {action: "click->play#playOrPause:prevent"})
      end

      play_button + video_element + gif_badge + alt_text_badge
    end
  end

  def media_gallery_video_tag(media_attachment, i:, total:)
    classes = %w[flex justify-center items-center cursor-pointer relative]
    classes << "row-span-2" if i == 0 && total == 3

    data = {
      "lg-size" => [media_attachment.width.to_i, media_attachment.height.to_i].join("-"),
      "poster" => cdn_file_url(media_attachment.preview_image),
      "video" => {
        source: [{
          src: cdn_file_url(media_attachment),
          type: media_attachment.content_type
        }],
        attributes: {
          preload: false,
          playsinline: true,
          controls: true
        }
      }.to_json
    }

    tag.a(class: classes, data: data) do
      image_classes = %w[object-cover]
      image_classes += additional_classes_for(file: media_attachment, i: i, total: total)

      image_element = image_tag(cdn_file_url(media_attachment.preview_image), loading: "lazy", alt: media_attachment.description, class: image_classes)

      duration_badge = tag.div(class: "absolute left-2 bottom-2") do
        mm, ss = media_attachment.metadata[:duration].to_i.divmod(60)
        duration = "#{mm}:#{ss.to_s.rjust(2, "0")}"

        tag.button(duration, class: "font-bold font-ui-sans rounded-[.25rem] bg-black bg-opacity-[.65] text-white hover:bg-black px-1 select-none", data: {action: "click->play#playOrPause:prevent"})
      end

      # Just to ensure the video is included in microformats, we'll include a
      # hidden video element that is not visible to the user.
      hidden_video_element = content_tag("video", media_attachment.description, src: cdn_file_url(media_attachment.file), preload: "none", class: "u-video hidden")

      play_button + image_element + duration_badge + hidden_video_element
    end
  end

  def alt_text_badge(media_attachment, fully_rounded: true)
    return if media_attachment.description.blank?

    badge_classes = %w[absolute bottom-2]
    badge_classes << (fully_rounded ? "left-2" : "left-11")

    # Might seem weird to add aria-hidden to an alt text tooltip, but the tooltip
    # is really for people who _aren't_ using a screen reader. For screen readers,
    # the alt text is already available as the alt attribute on the image. So this
    # is just to prevent screen readers from reading the alt text twice.
    tag.div(class: badge_classes, data: {"controller" => "alt-text", "aria-hidden" => true, "alt-text-content-value" => media_attachment.description}) do
      button_classes = %w[font-bold font-ui-sans bg-black bg-opacity-[.65] text-white hover:bg-black px-1 select-none]
      button_classes << (fully_rounded ? "rounded-[.25rem]" : "rounded-r-[.25rem]")

      tag.button("ALT", class: button_classes, data: {"action" => "click->alt-text#ignore:prevent", "alt-text-target" => "trigger"})
    end
  end

  def play_button
    @play_button_tag ||= tag.button(class: "absolute z-10", data: {"play-target" => "button"}) do
      tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 512 512", class: "w-16 h-16 rounded-full bg-white border-4 border-white fill-pink-500 hover:fill-pink-700") do
        tag.path(d: "M512 256c0 141.4-114.6 256-256 256S0 397.4 0 256S114.6 0 256 0S512 114.6 512 256zM188.3 147.1c-7.6 4.2-12.3 12.3-12.3 20.9V344c0 8.7 4.7 16.7 12.3 20.9s16.8 4.1 24.3-.5l144-88c7.1-4.4 11.5-12.1 11.5-20.5s-4.4-16.1-11.5-20.5l-144-88c-7.4-4.5-16.7-4.7-24.3-.5z")
      end
    end
  end

  def additional_classes_for(file:, i:, total:)
    classes = (total <= 2) ? ["max-h-[500px]"] : []

    if total == 1
      classes << "rounded-lg"
      classes << "aspect-[1/1]" if file.image? && file.height > file.width
      return classes
    end

    classes << "aspect-[4/3]" if total > 1

    case i
    when 0
      classes << "rounded-tl-lg"
      classes << "rounded-bl-lg" if total <= 3
    when 1
      classes << "rounded-tr-lg"
      classes << "rounded-br-lg" if total == 2
    when 2
      classes << "rounded-br-lg" if total == 3
      classes << "rounded-bl-lg" if total == 4
    when 3
      classes << "rounded-br-lg"
    end

    classes
  end
end
