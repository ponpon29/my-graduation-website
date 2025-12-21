class Admin::ShopsController < Admin::BaseController
  before_action :set_shop, only: [:show, :edit, :update, :destroy]
  
  # 店舗一覧
  def index
    @shops = Shop.all.order(created_at: :desc)
  end
  
  # 店舗詳細
  def show
    # @shop は before_action で設定済み
  end
  
  # 店舗新規作成
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
  
  # 店舗編集
  def edit
  end
  
  def update
    if @shop.update(shop_params)
      redirect_to admin_shop_path(@shop), success: '店舗を更新しました'
    else
      flash.now[:danger] = '店舗の更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @shop.destroy!
    redirect_to admin_shops_path, success: '店舗を削除しました', status: :see_other
  end
  
  private
  
  def set_shop
    @shop = Shop.find(params[:id])
  end
  
  def shop_params
    params.require(:shop).permit(:name, :address, :phone_number, :description, :shop_image)
  end
end