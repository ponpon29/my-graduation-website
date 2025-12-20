class ReviewsController < ApplicationController
  before_action :require_login, except: [:index]
  before_action :set_shop_if_present, only: [:index]
  before_action :set_shop, only: [:new, :create, :edit, :update]
  before_action :set_review, only: [:destroy, :edit, :update]
  before_action :check_review_owner, only: [:edit, :update, :destroy]
  
  def index
    if @shop.present?
      @reviews = @shop.reviews.includes(:user).order(created_at: :desc).page(params[:page]).per(9)
      @review = Review.new if logged_in?
      @average_rating = @shop.reviews.average(:rating)&.round(1)
    else
      @reviews = Review.includes(:user, :shop).order(created_at: :desc).page(params[:page]).per(9)
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
      @reviews = @shop.reviews.includes(:user).order(created_at: :desc)
      @average_rating = @shop.reviews.average(:rating)&.round(1)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_path = determine_redirect_path_from_params
      redirect_to redirect_path, success: 'レビューを更新しました！'
    else
      flash.now[:danger] = 'レビューの更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    shop = @review.shop
    @review.destroy

    flash.now[:success] = 'レビューを削除しました'
  end
  
  private
  
  def set_shop
    @shop = Shop.find(params[:shop_id])
  end
  
  def set_review
    @review = Review.find(params[:id])
    @shop = @review.shop
  end

  def set_shop_if_present
    @shop = Shop.find(params[:shop_id]) if params[:shop_id].present?
  end

  def check_review_owner
    unless @review.user == current_user
      redirect_to @shop, alert: '権限がありません'
      return
    end
  end

  def review_params
    params.require(:review).permit(:rating, :content, :review_image)
  end

  def determine_redirect_path_from_params(shop = nil)
    target_shop = shop || @review.shop
    
    case params[:return_to]
    when 'mypage'
      user_path(current_user)
    when 'shop'
      shop_path(target_shop, tab: 'reviews')
    when 'reviews'
      reviews_path
    when 'shop_reviews'
      shop_reviews_path(target_shop)
    else
      shop_path(target_shop, tab: 'reviews')
    end
  end
end
