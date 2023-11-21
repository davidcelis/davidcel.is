class Link < Post
  DEFAULT_INCLUDES = [
    {favicon_attachment: :blob},
    {preview_image_attachment: :blob}
  ]

  validates :title, presence: true
  validates :link_data, presence: true

  has_one_attached :favicon
  has_one_attached :preview_image

  # Allow searching Links by href, title, and content.
  pg_search_scope :search,
    against: [:title, :href, :content],
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  def to_param
    slug
  end

  def excerpt
    @excerpt ||= if html.include?(Post::EXCERPT_SEPARATOR)
      html.split(Post::EXCERPT_SEPARATOR).first.strip
    else
      html
    end
  end

  def base_url
    @base_url ||= uri.tap { |uri| uri.path = "" }.to_s
  end

  def domain
    @domain ||= uri.host.sub(/^www\./, "")
  end

  private

  def generate_slug
    self.slug = [id, title].join("-").gsub(/['’]/, "").parameterize
  end

  def uri
    @uri ||= URI.parse(link_data["url"])
  end
end
