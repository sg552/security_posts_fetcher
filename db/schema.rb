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

ActiveRecord::Schema[7.0].define(version: 2022_12_27_034615) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blogs", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "author"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "blog_url"
    t.string "author_url"
    t.string "source_website"
    t.integer "views"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.integer "blog_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "special_column_id"
  end

  create_table "proxies", force: :cascade do |t|
    t.string "ip"
    t.integer "port"
    t.string "external_ip"
    t.datetime "expiration_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "special_columns", force: :cascade do |t|
    t.string "name"
    t.string "source_website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
