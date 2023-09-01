class Place < ApplicationRecord
  APPLE_MAPS_BASE_URL = "https://maps.apple.com/place".freeze

  has_many :check_ins

  validates :name, presence: true
  validates :coordinates, presence: true

  def latitude
    coordinates.y
  end

  def longitude
    coordinates.x
  end

  def apple_maps_url
    super || begin
      params = {q: name, ll: [latitude, longitude].join(",")}
      params[:auid] = apple_maps_id if apple_maps_id.present?

      uri = URI(APPLE_MAPS_BASE_URL)
      uri.query = params.to_query

      uri.to_s
    end
  end
end
