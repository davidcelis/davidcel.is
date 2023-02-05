class Article < Post
  # Allow Articles to have footnotes, tables, and task lists.
  self.markdown_parsing_options = [:UNSAFE, :SMART, :FOOTNOTES]
  self.markdown_rendering_options = markdown_parsing_options
  self.markdown_extensions = [:strikethrough, :table, :tasklist]

  validates :title, presence: true

  def excerpt
    @excerpt ||= html.split("<!--more-->").first.strip
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
    @commonmark_doc ||= CommonMarker.render_doc(content, markdown_parsing_options, markdown_extensions)
  end
end
