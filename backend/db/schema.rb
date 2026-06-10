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

ActiveRecord::Schema[8.1].define(version: 2026_06_10_070807) do
  create_table "expenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "deleted_at"
    t.bigint "group_id", null: false
    t.text "note"
    t.bigint "paid_by_id", null: false
    t.date "paid_on", null: false
    t.string "public_id", limit: 26, null: false
    t.string "split_type", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "fk_rails_f7e2e7081b"
    t.index ["group_id", "deleted_at"], name: "index_expenses_on_group_id_and_deleted_at"
    t.index ["group_id", "paid_on"], name: "index_expenses_on_group_id_and_paid_on"
    t.index ["paid_by_id"], name: "index_expenses_on_paid_by_id"
    t.index ["public_id"], name: "index_expenses_on_public_id", unique: true
    t.check_constraint "`amount_cents` > 0", name: "chk_expenses_amount_positive"
    t.check_constraint "`split_type` in (_utf8mb4'EQUAL_ALL',_utf8mb4'EQUAL_SELECTED',_utf8mb4'AMOUNT',_utf8mb4'PERCENT')", name: "chk_expenses_split_type"
  end

  create_table "groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "JPY", null: false
    t.string "invite_token", null: false
    t.datetime "invite_token_expires_at", null: false
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

  create_table "splits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "expense_id", null: false
    t.integer "share_cents", null: false
    t.integer "share_percent"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expense_id", "user_id"], name: "index_splits_on_expense_id_and_user_id", unique: true
    t.index ["expense_id"], name: "index_splits_on_expense_id"
    t.index ["user_id"], name: "fk_rails_d13926f60f"
    t.check_constraint "`share_cents` >= 0", name: "chk_splits_share_cents_non_negative"
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

  add_foreign_key "expenses", "groups"
  add_foreign_key "expenses", "users", column: "created_by_id"
  add_foreign_key "expenses", "users", column: "paid_by_id"
  add_foreign_key "members", "groups"
  add_foreign_key "members", "users"
  add_foreign_key "splits", "expenses"
  add_foreign_key "splits", "users"
end
