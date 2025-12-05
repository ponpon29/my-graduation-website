class SearchController < ApplicationController
  skip_before_action :require_login, only: [:menu, :location, :shop]
  
  def menu
  end

  def location
    @shops = Shop.all
  end

  def shop
    @q = Shop.ransack(params[:q])
    
    @shops = @q.result(distinct: true)
  end
end