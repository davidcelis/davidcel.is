class Webmention < ApplicationRecord
  self.inheritance_column = nil

  include SnowflakeID

  belongs_to :post, optional: true

  validates :source, presence: true
  validates :target, presence: true

  enum status: {
    unprocessed: "unprocessed",
    verified: "verified",
    failed: "failed"
  }

  enum type: {
    like: "like",
    repost: "repost",
    reply: "reply",
    mention: "mention"
  }

  def h_entry
    @h_entry ||= begin
      mf2 = Microformats::Collection.new(self.mf2)
      mf2.entry if mf2.respond_to?(:entry)
    end
  end

  def published_at
    @published_at ||= Time.zone.parse(h_entry.published)
  end
end
