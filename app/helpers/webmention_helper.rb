module WebmentionHelper
  def like_tag(like)
    return unless like.h_entry.present?

    original_url = like.h_entry.url
    author = like.h_entry.author
    author_name = author.name if author.respond_to?(:name)
    author_name ||= author.nickname if author.respond_to?(:nickname)

    link_to(original_url, title: author_name, target: "_blank", aria: {label: "Liked by #{author_name}"}) do
      avatar_tag(like.h_entry.author)
    end
  end

  def repost_tag(repost)
    return unless repost.h_entry.present?

    original_url = repost.h_entry.url
    author = repost.h_entry.author
    author_name = author.name if author.respond_to?(:name)
    author_name ||= author.nickname if author.respond_to?(:nickname)

    link_to(original_url, title: author_name, target: "_blank", aria: {label: "Reposted by #{author_name}"}) do
      avatar_tag(repost.h_entry.author)
    end
  end

  def avatar_tag(author)
    fallback_image = "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(author.url)}.png?d=identicon"
    author_image = author.photo if author.respond_to?(:photo)
    author_image ||= fallback_image

    image_tag(author_image, class: "inline-block h-8 w-8 rounded-full ring-2 ring-white", onerror: "this.src='#{fallback_image}'")
  end

  def reply_photo_gallery_tag(urls)
    gallery_length = urls.length
    return if gallery_length == 0

    classes = %w[grid gap-x-1 gap-y-1 mt-4 overflow-hidden]
    classes << "grid-cols-2" if gallery_length >= 2

    data = {
      "controller" => "lightbox",
      "lightbox-options-value" => {
        video: false,
        counter: gallery_length > 1
      }.to_json
    }

    tag.div(class: classes, data: data) do
      urls.map.with_index do |url, i|
        reply_photo_tag(url, i: i, total: gallery_length)
      end.join.html_safe
    end
  end

  private

  def reply_photo_tag(url, i:, total:)
    classes = ["relative"]
    classes << "row-span-2" if i == 0 && total == 3

    link_to url, class: classes do
      image_classes = %w[object-cover height-full w-full]
      image_classes += additional_photo_classes(i: i, total: total)

      image_tag(url, loading: "lazy", class: image_classes, onerror: "this.src='#{asset_path("fallback.jpg")}'")
    end
  end

  def additional_photo_classes(i:, total:)
    classes = (total <= 2) ? ["max-h-[500px]"] : []

    if total == 1
      classes << "rounded-lg"
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
