class Post < ApplicationRecord
  include PgSearch::Model
  include SnowflakeID

  EXCERPT_SEPARATOR = "<!--more-->".freeze
  DEFAULT_INCLUDES = [
    :place,
    :syndication_links,
    {
      media_attachments: {
        file_attachment: :blob,
        webp_variant_attachment: :blob,
        preview_image_attachment: :blob
      }
    }
  ].freeze

  class_attribute :markdown_parsing_options, instance_writer: false
  class_attribute :markdown_rendering_options, instance_writer: false
  class_attribute :markdown_extensions, instance_writer: false

  # These are the defaults we'll likely want for most post types.
  self.markdown_parsing_options = [:UNSAFE, :SMART]
  self.markdown_rendering_options = [:UNSAFE, :SMART, :HARDBREAKS]
  self.markdown_extensions = [:strikethrough]

  URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])
  HASHTAG_REGEX = /(?<=^|[^\/\w])#(\S+)/i
  MASTODON_MENTION_REGEX = /(?<=^|[^\/\w])@(?:([a-z0-9_]+)@((?:[\w.-]+\w+)?))/i
  BLUESKY_MENTION_REGEX = /(?<=^|[^\/\w])@(([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,})/i

  belongs_to :place, optional: true
  has_many :media_attachments, dependent: :destroy
  has_many :syndication_links, dependent: :destroy

  validates :content, presence: true, unless: -> { type == "CheckIn" || media_attachments.any? }

  before_create :generate_slug
  before_save :sanitize_content
  before_save :update_html, if: :content_changed?
  before_save :clear_coordinates, if: -> { latitude.blank? || longitude.blank? }

  after_commit :syndicate, on: [:create, :update]
  before_destroy :unsyndicate, prepend: true

  default_scope { order(id: :desc) }

  scope :main, -> { where(type: %w[Article Link Note]) }

  # Allow searching Posts by content and the name of wherever they were posted.
  # I could allow more specificity for searching against the associated Place,
  # but I think it's better to just switch to a Check-in search for that.
  pg_search_scope :search,
    against: [:title, :content],
    associated_against: {place: :name},
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  def update_html
    self.html = Markdown::Renderer.new(options: markdown_rendering_options, extensions: markdown_extensions).render(commonmark_doc).strip
  end

  def latitude
    coordinates.y
  end

  def latitude=(value)
    coordinates.y = value.presence
  end

  def longitude
    coordinates.x
  end

  def longitude=(value)
    coordinates.x = value.presence
  end

  def coordinates
    super || (self.coordinates = ActiveRecord::Point.new)
  end

  private

  def syndicate
    SyndicateToMastodonJob.perform_async(id)
    SyndicateToBlueskyJob.perform_async(id)
  end

  def unsyndicate
    if (mastodon_link = syndication_links.find_by(platform: "mastodon"))
      status_id = mastodon_link.url.split("/").last
      DeleteFromMastodonJob.perform_async(status_id)
    end

    if (bluesky_link = syndication_links.find_by(platform: "bluesky"))
      rkey = bluesky_link.url.split("/").last
      DeleteFromBlueskyJob.perform_async(rkey)
    end
  end

  def generate_slug
    raise NoMethodError, "Subclasses must implement `generate_slug`"
  end

  def clear_coordinates
    self.coordinates = nil
  end

  # This is a catch-all method for sanitizing content before it's saved to the
  # database, and is where we'll do things like strip leading or trailing
  # whitespace and converting carriage returns from CodeMirror to newlines.
  def sanitize_content
    self.content = content.strip.gsub(/\r\n?/, "\n")
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
        elsif (match = part.match(MASTODON_MENTION_REGEX))
          link_node = Markdown::Nodes::Link.from_mention(match[1], match[2])

          # Mentions are a bit more complicated, because we need to handle when
          # the mention is possessive or wrapped in something like parens or quotes.
          # We'll handle this by splitting the string on the mention and then
          # recombining it with the link node in the middle.
          index = part.index(MASTODON_MENTION_REGEX)
          new_text += part[0...index]
          part = part[index..]

          new_text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = new_text }

          node.insert_before(new_text_node)
          node.insert_before(link_node)

          new_text = part.sub(MASTODON_MENTION_REGEX, "")
        elsif (match = part.match(BLUESKY_MENTION_REGEX))
          # Bluesky mentions are way simpler, because the domain name is the handle
          # and you link to it on bsky.app.
          link_node = Markdown::Nodes::Link.from_mention(match[1], "bsky.app")

          index = part.index(BLUESKY_MENTION_REGEX)
          new_text += part[0...index]
          part = part[index..]

          new_text_node = CommonMarker::Node.new(:text).tap { |n| n.string_content = new_text }

          node.insert_before(new_text_node)
          node.insert_before(link_node)

          new_text = part.sub(BLUESKY_MENTION_REGEX, "")
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
