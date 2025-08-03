class MapsController < ApplicationController
  skip_before_action :require_login

  def index
    @shops = Shop.all
  end
end
