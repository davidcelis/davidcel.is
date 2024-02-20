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
end
