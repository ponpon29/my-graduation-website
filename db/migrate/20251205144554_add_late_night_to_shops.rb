class AddLateNightToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :late_night, :boolean, default: false, null: false
  end
end