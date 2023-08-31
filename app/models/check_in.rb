class CheckIn < Post
  belongs_to :place

  validates :title, absence: true

  has_one_attached :snapshot

  after_create :generate_snapshot

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = [id, place.name.parameterize].join("-")
  end

  def generate_snapshot
    GenerateSnapshotJob.perform_async(id)
  end

  def syndicate
    # Don't bother syndicating check-ins.
  end
end
