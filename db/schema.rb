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

ActiveRecord::Schema[8.1].define(version: 2026_03_24_024331) do
  create_table "diff_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "diff_data"
    t.integer "snapshot_a_id", null: false
    t.integer "snapshot_b_id", null: false
    t.string "summary"
    t.datetime "updated_at", null: false
    t.index ["snapshot_a_id"], name: "index_diff_reports_on_snapshot_a_id"
    t.index ["snapshot_b_id"], name: "index_diff_reports_on_snapshot_b_id"
  end

  create_table "endpoints", force: :cascade do |t|
    t.integer "baseline_snapshot_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.text "headers"
    t.string "http_method"
    t.string "name"
    t.integer "project_id", null: false
    t.string "schedule"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["project_id"], name: "index_endpoints_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "endpoint_id", null: false
    t.string "name"
    t.text "response_body"
    t.integer "response_time_ms"
    t.integer "status_code"
    t.datetime "taken_at"
    t.string "triggered_by"
    t.datetime "updated_at", null: false
    t.index ["endpoint_id"], name: "index_snapshots_on_endpoint_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "diff_reports", "snapshots", column: "snapshot_a_id"
  add_foreign_key "diff_reports", "snapshots", column: "snapshot_b_id"
  add_foreign_key "endpoints", "projects"
  add_foreign_key "projects", "users"
  add_foreign_key "snapshots", "endpoints"
end
