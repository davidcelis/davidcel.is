class Webmention < ApplicationRecord
  validates :source, presence: true
  validates :target, presence: true

  enum status: {unprocessed: "unprocessed", verified: "verified", failed: "failed"}

  after_commit :process

  private

  def process
    ProcessWebmentionJob.perform_later(id)
  end
end
