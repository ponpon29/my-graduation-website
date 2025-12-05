class AddDensityToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :density, :integer, null: false, default: 0
  end
end
