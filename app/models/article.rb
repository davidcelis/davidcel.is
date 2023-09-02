class Article < Post
  EXCERPT_SEPARATOR = "<!--more-->".freeze

  # Allow Articles to have footnotes, tables, and task lists.
  self.markdown_parsing_options = [:UNSAFE, :SMART, :FOOTNOTES]
  self.markdown_rendering_options = [:UNSAFE, :SMART, :FOOTNOTES]
  self.markdown_extensions = [:strikethrough, :table, :tasklist]

  validates :title, presence: true

  def excerpt
    @excerpt ||= if html.include?(EXCERPT_SEPARATOR)
      html.split(EXCERPT_SEPARATOR).first.strip
    else
      html.split(/(?<=<\/p>)/).first.strip
    end
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.tr("'", "").parameterize
  end

  # Override the default `commonmark_doc` method to prevent the auto-linking we
  # do for other posts; I'm careful about explicit links in my articles.
  def commonmark_doc
    return @commonmark_doc if defined?(@commonmark_doc) && !content_changed?

    @commonmark_doc = CommonMarker.render_doc(content, markdown_parsing_options, markdown_extensions)
  end
end
