class CreateShops < ActiveRecord::Migration[7.2]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :postal_code
      t.string :address
      t.string :phone
      t.string :opening_hours
      t.string :website
      t.decimal :rating
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.string :place_id, null: false
      t.string :photo_url

      t.timestamps
    end
  end
end
