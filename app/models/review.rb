class Review < ApplicationRecord
  belongs_to :user
  belongs_to :shop

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
