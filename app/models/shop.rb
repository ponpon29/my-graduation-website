class Shop < ApplicationRecord
  belongs_to :user, optional: true
  has_many :favorites, dependent: :destroy
  has_many :reviews, dependent: :destroy

  def average_rating
    reviews.average(:rating)&.round(1) || 0
  end
end
