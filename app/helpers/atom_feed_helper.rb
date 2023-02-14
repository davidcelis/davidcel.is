module AtomFeedHelper
  def atom_content_for(post)
    case post
    when Article
      atom_article_content(post)
    when Note
      atom_note_content(post)
    end
  end

  private

  def atom_article_content(article)
    html = "#{article.excerpt}<p>#{link_to "Continue reading…", polymorphic_url(article)}</p>"

    if (image = article.media_attachments.first(&:image?))
      html = "#{image_tag(cdn_file_url(image), alt: image.description)}#{html}"
    end

    html
  end

  def atom_note_content(note)
    note.media_attachments.reduce(note.html) do |html, media_attachment|
      html + atom_media_tag(media_attachment)
    end
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
