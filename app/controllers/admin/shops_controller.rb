class Admin::ShopsController < Admin::BaseController
  before_action :set_shop, only: [:edit, :destroy]
  
  def index
    @shops = Shop.page(params[:page])
  end
  
  def new
    @shop = Shop.new
  end
  
  def create
    @shop = Shop.new(shop_params)
    if @shop.save
      redirect_to admin_shop_path(@shop), success: '店舗を作成しました'
    else
      flash.now[:danger] = '店舗の作成に失敗しました'
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def destroy
    @shop.destroy!
    
    respond_to do |format|
      format.html { redirect_to admin_shops_path, success: '店舗を削除しました', status: :see_other }
      format.turbo_stream
    end
  end
  
  private
  
  def set_shop
    @shop = Shop.find(params[:id])
  end
  
  def shop_params
    params.require(:shop).permit(:name, :address, :phone, :photo_url)
  end
end