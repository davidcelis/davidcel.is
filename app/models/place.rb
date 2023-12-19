class Place < ApplicationRecord
  APPLE_MAPS_BASE_URL = "https://maps.apple.com/".freeze

  include SnowflakeID

  has_many :check_ins

  validates :name, presence: true
  validates :coordinates, presence: true, if: -> { apple_maps_id.present? }

  def latitude
    coordinates&.y
  end

  def latitude=(value)
    self.coordinates ||= ActiveRecord::Point.new
    coordinates.y = value
  end

  def longitude
    coordinates&.x
  end

  def longitude=(value)
    self.coordinates ||= ActiveRecord::Point.new
    coordinates.x = value
  end

  def city_state_and_country(separator: ", ")
    parts = [city, state_code || state]
    parts << (country_code || country) unless country_code == "US" || country == "United States"

    parts.compact.join(separator)
  end

  def apple_maps_url
    super || begin
      params = {q: name}

      if latitude.present? && longitude.present?
        params[:ll] = [latitude, longitude].join(",")
      else
        params[:q] += ", #{city_state_and_country}, #{country_code || country}"
      end

      params[:auid] = apple_maps_id if apple_maps_id.present?

      uri = URI(APPLE_MAPS_BASE_URL)
      uri.query = params.to_query

      uri.to_s
    end
  end
end
