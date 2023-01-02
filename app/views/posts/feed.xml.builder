xml.instruct! :xml, version: "1.0"
xml.rss "version" => "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "davidcel.is"
    xml.link root_url
    xml.description "Musings of a cowboy coder."
    xml.pubDate @posts.first.created_at.rfc822
    xml.lastBuildDate @posts.first.created_at.rfc822
    xml.language "en-us"

    xml.image do
      xml.title "davidcel.is"
      xml.url asset_url("me.jpg")
      xml.link root_url
    end

    xml.tag! "atom:link", rel: "self", type: "application/rss+xml", href: feed_url(format: :xml)

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description html_escape(post.excerpt)
        xml.pubDate post.created_at.rfc822

        xml.link polymorphic_url(post)
        xml.guid post_url(post.id)
      end
    end
  end
end
