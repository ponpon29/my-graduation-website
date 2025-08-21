class ShopsController < ApplicationController
  skip_before_action :require_login, only: [:index, :show, :favorites]
  
  def show
    @shop = Shop.find(params[:id])
  end

  def favorite
    @shop = Shop.find(params[:id])
    current_user.favorite(@shop)
    redirect_to @shop, success: 'お気に入りに追加しました'
  end

  def unfavorite
    @shop = Shop.find(params[:id])
    current_user.unfavorite(@shop)
    redirect_to @shop, success: 'お気に入りから削除しました'
  end

  def favorites
    @favorite_shops = current_user.favorite_shops.includes(:user)
  end
end
