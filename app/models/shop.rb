class Shop < ApplicationRecord
  serialize :photos, type: Array, coder: JSON

  belongs_to :user, optional: true
  has_many :favorites, dependent: :destroy
  has_many :reviews, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    ["address", "cashless", "created_at", "density", "id", "latitude", "longitude", "name", "opening_hours", "phone", "photo_url", "place_id", "postal_code", "rating", "updated_at", "website"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["favorites", "reviews", "user"]
  end

  def average_rating
    reviews.average(:rating)&.round(1) || 0
  end

  def get_photos
    photos.presence || []
  end
end