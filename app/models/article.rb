class Article < Post
  # Allow Articles to have footnotes, tables, and task lists.
  self.markdown_parsing_options = [:UNSAFE, :SMART, :FOOTNOTES]
  self.markdown_rendering_options = [:UNSAFE, :SMART, :FOOTNOTES]
  self.markdown_extensions = [:strikethrough, :table, :tasklist]

  validates :title, presence: true

  # Allow searching Articles by title and content.
  pg_search_scope :search,
    against: [:title, :content],
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  def excerpt
    @excerpt ||= if html.include?(Post::EXCERPT_SEPARATOR)
      html.split(Post::EXCERPT_SEPARATOR).first.strip
    else
      html.split(/(?<=<\/p>)/).first.strip
    end
  end

  def og_description
    @og_description ||= Nokogiri::HTML::DocumentFragment.parse(excerpt).at_css("p")&.text || excerpt
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.gsub(/['’]/, "").parameterize
  end

  # Override the default `commonmark_doc` method to prevent the auto-linking we
  # do for other posts; I'm careful about explicit links in my articles.
  def commonmark_doc
    return @commonmark_doc if defined?(@commonmark_doc) && !content_changed?

    @commonmark_doc = CommonMarker.render_doc(content, markdown_parsing_options, markdown_extensions)
  end
end
