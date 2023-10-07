class CheckIn < Post
  belongs_to :place

  validates :title, absence: true

  has_one_attached :snapshot

  # Allow searching Check-ins by content and location.
  pg_search_scope :search,
    against: :content,
    associated_against: {place: [:name, :city, :state, :state_code, :country, :country_code]},
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = [id, place.name].join("-").tr("'", "").first(72).parameterize
  end

  def syndicate
    # Don't bother with check-ins that weren't important enough to have pics or commentary.
    return unless content.present? || media_attachments.any?

    super
  end
end
