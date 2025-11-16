class AddReviewImageToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :review_image, :string
  end
end
