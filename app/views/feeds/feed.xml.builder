xml.instruct! :xml, version: "1.0"
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "davidcel.is"
  xml.subtitle @subtitle if @subtitle.present?
  xml.author do
    xml.name "David Celis"
    xml.email "me@davidcel.is"
    xml.uri root_url
  end

  xml.icon asset_url("me.jpg")
  xml.logo asset_url("me.jpg")

  xml.link rel: "alternate", type: "text/html", href: @alternate_url
  xml.link rel: "self", type: "application/atom+xml", href: @self_url

  xml.id @self_url
  xml.updated @posts.first.created_at.iso8601
  xml.rights "© #{Date.today.year} David Celis"

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post.id)
      xml.title atom_title_for(post)

      xml.content "type" => "html", "xml:lang" => "en" do
        xml.cdata! atom_content_for(post)
      end

      xml.published post.created_at.iso8601
      xml.updated post.updated_at.iso8601

      if post.is_a?(Link)
        xml.link rel: "alternate", type: "text/html", href: post.link_data["url"]
        xml.link rel: "related", type: "text/html", href: polymorphic_url(post)
      else
        xml.link rel: "alternate", type: "text/html", href: polymorphic_url(post)
      end
    end
  end
end
