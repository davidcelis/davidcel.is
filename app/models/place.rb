class Place < ApplicationRecord
  has_many :check_ins

  validates :name, presence: true
  validates :coordinates, presence: true

  def latitude
    coordinates.y
  end

  def longitude
    coordinates.x
  end
end
