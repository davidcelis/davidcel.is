class Webmention < ApplicationRecord
  belongs_to :post, optional: true

  validates :source, presence: true
  validates :target, presence: true

  enum status: {unprocessed: "unprocessed", verified: "verified", failed: "failed"}
end
