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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_180000) do
  create_table "activities", force: :cascade do |t|
    t.bigint "opportunity_id", null: false
    t.string "kind", null: false
    t.date "occurred_on", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["opportunity_id", "occurred_on"], name: "index_activities_on_opportunity_id_and_occurred_on"
    t.index ["opportunity_id"], name: "index_activities_on_opportunity_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "opportunities", force: :cascade do |t|
    t.string "company", null: false
    t.string "role", null: false
    t.string "kind"
    t.string "source"
    t.string "status", default: "not_contacted", null: false
    t.integer "pay_min"
    t.integer "pay_max"
    t.string "pay_unit", default: "yearly"
    t.string "url"
    t.date "contacted_on"
    t.date "follow_up_on"
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "due", default: false, null: false
    t.string "closed_reason"
    t.datetime "archived_at"
    t.string "external_id"
    t.date "last_verified_on"
    t.string "resume_version"
    t.string "contact_name"
    t.string "application_channel"
    t.index ["archived_at"], name: "index_opportunities_on_archived_at"
    t.index ["due"], name: "index_opportunities_on_due"
    t.index ["external_id"], name: "index_opportunities_on_external_id", unique: true
    t.index ["follow_up_on"], name: "index_opportunities_on_follow_up_on"
    t.index ["status", "position"], name: "index_opportunities_on_status_and_position"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "activities", "opportunities"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "sessions", "users"
end
