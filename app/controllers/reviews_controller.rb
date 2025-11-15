class ReviewsController < ApplicationController
  before_action :require_login, except: [:index]
  before_action :set_shop_if_present, only: [:index]
  before_action :set_shop, only: [:new, :create]
  before_action :set_review, only: [:destroy]
  
  def index
    if @shop.present?
      @reviews = @shop.reviews.includes(:user).order(created_at: :desc)
      @review = Review.new if logged_in?
      @average_rating = @shop.reviews.average(:rating)&.round(1)
    else
      @reviews = Review.includes(:user, :shop).order(created_at: :desc)
      @review = nil
      @average_rating = nil
    end
  end

  def new
    @review = Review.new
  end
  
  def create
    @review = @shop.reviews.build(review_params)
    @review.user = current_user
    
    if @review.save
      redirect_to shop_path(@shop, tab: 'reviews'), success: 'レビューを投稿しました'
    else
      @reviews = @shop.reviews.includes(:user).recent
      @average_rating = @shop.reviews.average(:rating)&.round(1)
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @review.destroy
    redirect_to shop_reviews_path(@review.shop), notice: 'レビューを削除しました'
  end
  
  private
  
  def set_shop
    @shop = Shop.find(params[:shop_id])
  end
  
  def set_review
    @review = current_user.reviews.find(params[:id])
  end
  
  def review_params
    params.require(:review).permit(:rating, :content, :image)
  end

  def set_shop_if_present
    @shop = Shop.find(params[:shop_id]) if params[:shop_id].present?
  end
end
