class AddDensityToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :density, :string
  end
end
