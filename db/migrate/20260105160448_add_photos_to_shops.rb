class AddPhotosToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :photos, :text
    add_column :shops, :photos_cached_at, :datetime
  end
end
