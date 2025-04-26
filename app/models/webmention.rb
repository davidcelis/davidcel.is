class Webmention < ApplicationRecord
  self.inheritance_column = nil

  include SnowflakeID

  belongs_to :post, optional: true

  validates :source, presence: true, url: true
  validates :target, presence: true, url: true
  validate :target_must_be_a_known_url

  enum :status, {
    unprocessed: "unprocessed",
    verified: "verified",
    failed: "failed"
  }

  enum :type, {
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

  private

  def target_must_be_a_known_url
    return if target.blank?

    # Ensure the target URL is our base URL
    if URI.parse(target).host == Rails.application.routes.default_url_options[:host]
      Rails.application.routes.recognize_path(target)
    else
      errors.add(:target, "must be a known URL on this website")
    end
  rescue ActionController::RoutingError
    errors.add(:target, "must be a known URL on this website")
  end
end
