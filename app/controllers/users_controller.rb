class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :set_user, only: %i[show edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path, success: t('users.create.success')
    else
      flash.now[:danger] = t('users.create.failure')
      render :new, status: :unprocessable_entity
    end
  end

  # マイページ表示
  def show
    # 他のユーザーのページを見ることができるか、自分のみかを判断
    @posts = @user.boards.order(created_at: :desc) if @user == current_user
    @favorite_shops = @user.favorite_shops.includes(:favorites)
  end

  # プロフィール編集画面
  def edit
    # 自分のプロフィールのみ編集可能
    redirect_to root_path, danger: '不正なアクセスです' unless @user == current_user

    render 'edit_profile'
  end

  # プロフィール更新
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
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  # プロフィール更新用のパラメータ（パスワード以外）
  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email, :bio, :avatar)
  end
end
