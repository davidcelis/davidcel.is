class Note < Post
  validates :title, absence: true

  private

  def generate_slug
    self.slug = commonmark_doc.to_plaintext.truncate_words(5).parameterize
  end
end
