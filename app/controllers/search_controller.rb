class SearchController < ApplicationController
  skip_before_action :require_login, only: [:menu, :location, :shop]
  
  def menu
  end

  def location
    @shops = Shop.all
  end

  def shop
    @shops = Shop.all
  end
end