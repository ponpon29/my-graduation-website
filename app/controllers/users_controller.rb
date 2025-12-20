class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :set_user, only: %i[show edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user)
      redirect_to root_path, success: t('users.create.success')
    else
      flash.now[:danger] = t('users.create.failure')
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tab = params[:tab].presence || "reviews"
  
    @reviews = @user.reviews
                    .includes(:shop)
                    .order(created_at: :desc)
                    .page(params[:reviews_page])
                    .per(9)
  
    @favorite_shops = @user.favorite_shops
                           .includes(:favorites)
                           .order(created_at: :desc)
                           .page(params[:favorites_page])
                           .per(9)
  end

  def edit
    redirect_to root_path, danger: '不正なアクセスです' unless @user == current_user

    render 'edit_profile'
  end

  def update
    if @user == current_user && @user.update(profile_params)
      redirect_to user_path(@user), success: 'プロフィールを更新しました'
    else
      flash.now[:danger] = 'プロフィールの更新に失敗しました'
      render 'edit_profile', status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
  
  def profile_params
    params.require(:user).permit(:username, :email, :bio, :avatar)
  end
end
