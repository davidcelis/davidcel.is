class Post < ApplicationRecord
  class_attribute :markdown_parsing_options, instance_writer: false
  class_attribute :markdown_rendering_options, instance_writer: false
  class_attribute :markdown_extensions, instance_writer: false

  # These are the defaults we'll likely want for most post types.
  self.markdown_parsing_options = [:UNSAFE, :SMART]
  self.markdown_rendering_options = [:UNSAFE, :SMART, :HARDBREAKS]
  self.markdown_extensions = [:strikethrough]

  MENTION_REGEX = /(?<=^|[^\/\w])@(?:([a-z0-9_]+)@((?:[\w.-]+\w+)?))/i
  URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  has_many :media_attachments, dependent: :destroy
  has_many :syndication_links, dependent: :destroy

  validates :content, presence: true, unless: -> { media_attachments.any? }

  before_create :generate_slug
  before_save :update_html, if: :content_changed?

  # after_commit :syndicate, on: :create

  default_scope { order(id: :desc) }

  def update_html
    self.html = Markdown::Renderer.new(options: markdown_rendering_options, extensions: markdown_extensions).render(commonmark_doc).strip
  end

  private

  def syndicate
    SyndicateToMastodonJob.perform_async(id)
  end

  def generate_slug
    raise NoMethodError, "Subclasses must implement `generate_slug`"
  end

  def commonmark_doc
    return @commonmark_doc if defined?(@commonmark_doc) && !content_changed?

    @commonmark_doc = CommonMarker.render_doc(content, markdown_parsing_options, markdown_extensions)

    # The standard autolink extension will end up converting Fediverse mentions
    # to `mailto:` links, so we'll handle autolinking ourselves by iterating
    # over any text node that isn't already inside of a link.
    @commonmark_doc.walk do |node|
      next unless node.type == :text && node.parent.type != :link

      parts = node.string_content.split(/(\s+)/)
      new_text = ""

      parts.each do |part|
        if (match = part.match(URL_REGEX))
          link_node = Markdown::Nodes::Link.from_url(match[0])
          new_text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = new_text }

          node.insert_before(new_text_node)
          node.insert_before(link_node)

          new_text = ""
        elsif (match = part.match(MENTION_REGEX))
          link_node = Markdown::Nodes::Link.from_mention(match[1], match[2])
          new_text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = new_text }

          node.insert_before(new_text_node)
          node.insert_before(link_node)

          new_text = ""
        else
          new_text += part
        end
      end

      node.string_content = new_text
      node.delete if node.string_content.length == 0
    end

    @commonmark_doc
  end
end
