class CheckIn < Post
  belongs_to :place

  validates :title, absence: true

  has_one_attached :snapshot

  # Allow searching Check-ins by content and location.
  pg_search_scope :search,
    against: :content,
    associated_against: {place: [:name, :city, :state, :state_code, :country, :country_code]},
    using: {tsearch: {prefix: true, dictionary: "english"}}

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = [id, place.name].join("-").tr("'", "").first(72).parameterize
  end

  def syndicate
    # Don't bother syndicating check-ins.
  end
end
