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

ActiveRecord::Schema[8.1].define(version: 2026_03_13_234813) do
  create_table "groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "JPY", null: false
    t.string "invite_token", null: false
    t.string "name", null: false
    t.string "public_id", limit: 26, null: false
    t.datetime "updated_at", null: false
    t.index ["invite_token"], name: "index_groups_on_invite_token", unique: true
    t.index ["public_id"], name: "index_groups_on_public_id", unique: true
  end

  create_table "members", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.string "public_id", limit: 26, null: false
    t.string "role", default: "MEMBER", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "user_id"], name: "index_members_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_members_on_group_id"
    t.index ["public_id"], name: "index_members_on_public_id", unique: true
    t.index ["user_id"], name: "fk_rails_2e88fb7ce9"
    t.check_constraint "`role` in (_utf8mb4'OWNER',_utf8mb4'MEMBER')", name: "chk_members_role"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "external_uid", null: false
    t.string "name"
    t.boolean "notify_email", default: true, null: false
    t.string "public_id", limit: 26, null: false
    t.string "theme_mode", default: "SYSTEM", null: false
    t.datetime "updated_at", null: false
    t.index ["external_uid"], name: "index_users_on_external_uid", unique: true
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
    t.check_constraint "`theme_mode` in (_utf8mb4'SYSTEM',_utf8mb4'LIGHT',_utf8mb4'DARK')", name: "chk_users_theme_mode"
  end

  add_foreign_key "members", "groups"
  add_foreign_key "members", "users"
end
