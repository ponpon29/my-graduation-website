class Admin::DashboardsController < Admin::BaseController
  def index
    @shops_count = Shop.count
    @users_count = User.count
    @reviews_count = Review.count
    
    @recent_shops = Shop.order(created_at: :desc).limit(5)
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_reviews = Review.order(created_at: :desc).limit(5)
  end
end