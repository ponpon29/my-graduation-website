class User < ApplicationRecord
  authenticates_with_sorcery!

  mount_uploader :avatar, AvatarUploader
  
  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true

  has_many :boards, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_shops, through: :favorites, source: :shop

  def avatar_url
    avatar.present? ? avatar.url : nil
  end

  def favorite(shop)
    favorite_shops << shop unless favorite?(shop)
  end

  def unfavorite(shop)
    favorite_shops.destroy(shop)
  end

  def favorite?(shop)
    favorite_shops.include?(shop)
  end
end
