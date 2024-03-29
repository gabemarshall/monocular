# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 7) do

  create_table "domains", force: :cascade do |t|
    t.string "dns_name"
    t.string "dns_record"
    t.string "dns_record_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string "target"
    t.boolean "is_expired"
    t.string "schedule"
    t.string "arguments"
    t.string "uuid"
    t.string "add_tasks"
    t.datetime "datetime"
    t.string "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "task_type_id"
    t.text "output"
    t.integer "worker_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "ip"
    t.integer "port"
    t.text "banner"
    t.text "body"
    t.string "uri"
    t.string "service_type"
    t.string "hostname"
    t.string "status_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tokens", force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
