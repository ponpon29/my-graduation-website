class User < ApplicationRecord
  authenticates_with_sorcery! do |config|
    config.authentications_class = Authentication
  end

  mount_uploader :avatar, AvatarUploader
  
  validates :password, length: { minimum: 8 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, format: { with: /\A(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]+\z/,message: 'は英字と数字の両方を含めてください' }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :username, presence: true, length: { minimum: 3, maximum: 20 }
  validates :email, presence: true, uniqueness: true
  validates :reset_password_token, uniqueness: true, allow_nil: true

  has_many :reviews, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_shops, through: :favorites, source: :shop
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  def avatar_url
    avatar.present? ? avatar.url : nil
  end

  def display_name
    username
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

  def deliver_reset_password_instructions!
    regenerate_reset_password_token!
    UserMailer.reset_password_email(self).deliver_now
  end

  private

  def regenerate_reset_password_token!
    self.reset_password_token = generate_reset_password_token
    self.reset_password_token_expires_at = Time.current + reset_password_expiration_period
    save!(validate: false)
  end

  def generate_reset_password_token
    loop do
      token = SecureRandom.urlsafe_base64
      break token unless User.exists?(reset_password_token: token)
    end
  end

  def reset_password_expiration_period
    1.hour
  end
end
