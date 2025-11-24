class ShopsController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  
  def show
    @shop = Shop.find(params[:id])

    @reviews = @shop.reviews.includes(:user).order(created_at: :desc)

    @review = Review.new if logged_in?

  end
end