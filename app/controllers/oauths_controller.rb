class OauthsController < ApplicationController
  skip_before_action :require_login, raise: false
  
  def oauth
    login_at(params[:provider])
  end

  def callback
    provider = params[:provider]
    
    if @user = login_from(provider)
      redirect_to root_path, success: "#{provider.titleize}でログインしました"
    else
      begin
        @user = create_from(provider)
        reset_session
        auto_login(@user)
        redirect_to root_path, success: "#{provider.titleize}でアカウントを作成し、ログインしました"
      rescue => e
        Rails.logger.error "OAuth user creation failed: #{e.message}"
        redirect_to login_path, danger: "#{provider.titleize}でのログインに失敗しました"
      end
    end
  end

  def failure
    redirect_to login_path, danger: "認証がキャンセルされました"
  end
end