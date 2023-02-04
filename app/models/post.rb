class Post < ApplicationRecord
  MARKDOWN_MODE = [:UNSAFE, :FOOTNOTES, :SMART]
  MARKDOWN_EXTENSIONS = [:strikethrough]

  MENTION_REGEX = /(?<=^|[^\/\w])@(?:([a-z0-9_]+)@((?:[\w.-]+\w+)?))/i
  URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  has_many :media_attachments, dependent: :destroy

  validates :content, presence: true, unless: -> { media_attachments.any? }

  before_create :generate_slug
  before_save :render_html

  default_scope { order(id: :desc) }

  private

  def generate_slug
    raise NoMethodError, "Subclasses must implement `generate_slug`"
  end

  def render_html
    return unless content_changed?

    self.html = commonmark_doc.to_html(MARKDOWN_MODE, MARKDOWN_EXTENSIONS)
  end

  def commonmark_doc
    return @commonmark_doc if defined?(@commonmark_doc)

    doc = CommonMarker.render_doc(content, MARKDOWN_MODE, MARKDOWN_EXTENSIONS)

    # The standard autolink extension will end up converting Fediverse mentions
    # to `mailto:` links, so we'll handle autolinking ourselves.
    doc.walk do |node|
      next unless node.type == :text

      # First, automatically linkify any bare URLs
      text = node.string_content.gsub(URL_REGEX) do |url|
        scheme = url.match(%r{^https?://})[0]
        url_without_scheme = url.gsub(%r{^https?://(?:www\.)?}, "")
        display_url = url_without_scheme.truncate(30, omission: "")
        rest_of_url = url_without_scheme[display_url.length..]

        scheme_span = %(<span class="hidden">#{scheme}</span>)
        url_span = %(<span#{' class="ellipsis"' if rest_of_url.present?}>#{display_url}</span>)
        url_span += %(<span class="hidden">#{rest_of_url}</span>) if rest_of_url.present?

        %(<a href="#{url}" target="_blank" rel="nofollow noopener noreferrer" title="#{url}">#{scheme_span}#{url_span}</a>)
      end

      # Then, linkify mentions
      text = text.gsub(MENTION_REGEX) do
        username, domain = $1, $2
        url = "https://#{domain}/@#{username}"

        %(<a href="#{url}" target="_blank" rel="nofollow noopener noreferrer" title="#{username}@#{domain}">@#{username}</a>)
      end

      node.string_content = text
    end

    # Finally, re-render the document to plaintext (with an arbitrarily large
    # max width to avoid line wrapping), then re-parse it with CommonMarker so
    # that our automatic linkification doesn't get HTML-escaped.
    new_content = doc.to_plaintext(:DEFAULT, 1_000_000)

    @commonmark_doc = CommonMarker.render_doc(new_content, MARKDOWN_MODE, MARKDOWN_EXTENSIONS)
  end
end
