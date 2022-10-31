class Article < Post
  validates :title, presence: true

  def generate_slug
    self.slug = title.tr("'", "").parameterize
  end
end
