class Post < ApplicationRecord
  validates :content, presence: true

  before_create :generate_slug
  before_save :render_html

  default_scope { order(published_at: :desc) }

  def published?
    published_at.present?
  end

  def draft?
    !published?
  end

  private

  def generate_slug
    raise NoMethodError, "Subclasses must implement `generate_slug`"
  end

  def render_html
    return unless content_changed?

    self.html = commonmark_doc.to_html
  end

  def commonmark_doc
    CommonMarker.render_doc(content, :UNSAFE, [:strikethrough, :autolink])
  end
end
