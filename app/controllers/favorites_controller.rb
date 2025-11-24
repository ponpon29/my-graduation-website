class FavoritesController < ApplicationController
  before_action :require_login
  before_action :set_shop, only: [:create, :destroy]

  def create
    current_user.favorite(@shop)
  end

  def destroy
    current_user.unfavorite(@shop)
  end

  def index
    @favorite_shops = current_user.favorite_shops.includes(:user)
  end

  private

  def set_shop
    @shop = Shop.find(params[:shop_id])
  end
end