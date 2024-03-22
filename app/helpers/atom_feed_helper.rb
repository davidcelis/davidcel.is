module AtomFeedHelper
  def atom_title_for(post)
    case post
    when Article
      post.title
    when Link
      "🔗 #{post.title}"
    when CheckIn
      "📍#{post.place.name}"
    end

    # Default to no title.
  end

  def atom_content_for(post)
    case post
    when Article
      post.html
    when CheckIn
      atom_check_in_content(post)
    when Link
      atom_link_content(post)
    when Note
      atom_note_content(post)
    end
  end

  private

  def atom_check_in_content(check_in)
    place_parts = [
      link_to(check_in.place.name, check_in.place.apple_maps_url.html_safe).html_safe,
      check_in.place.city_state_and_country(separator: " / ")
    ]

    place_link = place_parts.join(" / ")

    html = content_tag(:p, "I checked in at #{place_link}".html_safe)
    html += content_tag(:blockquote, check_in.html.html_safe) if check_in.html.present?

    html = check_in.media_attachments.reduce(html) do |html, media_attachment|
      html + atom_media_tag(media_attachment)
    end

    if check_in.snapshot&.analyzed?
      html += image_tag(cdn_file_url(check_in.snapshot), alt: "A map showing the location of #{check_in.place.name}.") if check_in.snapshot.attached?
    end

    html
  end

  def atom_note_content(note)
    note.media_attachments.reduce(note.html) do |html, media_attachment|
      html + atom_media_tag(media_attachment)
    end
  end

  def atom_link_content(link)
    content = atom_note_content(link)

    content + content_tag(:p, link_to("🐴", polymorphic_url(link)))
  end

  def atom_media_tag(media_attachment)
    if media_attachment.image?
      image_tag(cdn_file_url(media_attachment), alt: media_attachment.description)
    elsif media_attachment.video_or_gif?
      options = {title: media_attachment.description, poster: cdn_file_url(media_attachment.preview_image)}
      options[:controls] = true unless media_attachment.gif?
      options[:loop] = true if media_attachment.gif?

      video_tag(cdn_file_url(media_attachment), options)
    end
  end
end
