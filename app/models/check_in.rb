class CheckIn < Post
  belongs_to :place

  validates :title, absence: true

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = [id, place.name.parameterize].join("-")
  end

  def syndicate
    # Don't bother syndicating check-ins.
  end
end
