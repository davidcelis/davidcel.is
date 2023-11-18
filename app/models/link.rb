class Link < Post
  validates :title, presence: true
  validates :link_data, presence: true

  # Allow searching Links by href, title, and content.
  pg_search_scope :search,
    against: [:title, :href, :content],
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = [id, title].join("-").tr("'", "").first(72).parameterize
  end
end
