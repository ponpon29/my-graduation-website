class ShopsController < ApplicationController
  skip_before_action :require_login
  
  def show
    @shop = Shop.find(params[:id])
  end
end
