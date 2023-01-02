class Article < Post
  validates :title, presence: true

  def excerpt
    @excerpt ||= html.split("<!--more-->").first.strip
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.tr("'", "").parameterize
  end
end
