# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_01_23_162247) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "postal_code"
    t.string "address"
    t.string "phone"
    t.string "opening_hours"
    t.string "website"
    t.decimal "rating"
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.string "place_id", null: false
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
