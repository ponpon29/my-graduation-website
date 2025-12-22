class Admin::ShopsController < Admin::BaseController
  before_action :set_shop, only: [:show, :edit, :destroy]
  
  def index
    @shops = Shop.all.order(created_at: :desc)
  end
  
  def show
  end
  
  def new
    @shop = Shop.new
  end
  
  def create
    @shop = Shop.new(shop_params)
    if @shop.save
      redirect_to admin_shops_path, success: '店舗を作成しました'
    else
      flash.now[:danger] = '店舗の作成に失敗しました'
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def destroy
    @shop.destroy!
    redirect_to admin_shops_path, success: '店舗を削除しました', status: :see_other
  end

  private
  
  private
  
  def set_shop
    @shop = Shop.find(params[:id])
  end
  
  def shop_params
    params.require(:shop).permit(:name, :address, :phone_number, :description, :shop_image)
  end
end