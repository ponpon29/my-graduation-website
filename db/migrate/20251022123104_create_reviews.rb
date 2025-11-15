class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
