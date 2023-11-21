class Note < Post
  validates :title, absence: true

  # Allow searching Notes by content and the name of wherever they were posted.
  pg_search_scope :search,
    against: :content,
    associated_against: {place: :name},
    using: {tsearch: {prefix: true, dictionary: "english"}},
    order_within_rank: "posts.created_at DESC"

  private

  def generate_slug
    self.slug = commonmark_doc.to_plaintext.truncate_words(5).gsub(/['’]/, "").parameterize
  end
end
