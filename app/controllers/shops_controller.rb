class ShopsController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  
  def show
    @shop = Shop.find(params[:id])
    @reviews = @shop.reviews.includes(:user).order(created_at: :desc).page(params[:reviews_page]).per(2)
    @review = Review.new if logged_in?

    respond_to do |format|
      format.html do
        if request.xhr? || params[:modal] == 'true'
          render partial: 'shops/modal_content', locals: { shop: @shop }
        else
          render :show
        end
      end
    end
  end
end
