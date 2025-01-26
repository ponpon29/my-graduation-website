class MapsController < ApplicationController
  def index
    @shops = Shop.all
  end
end
