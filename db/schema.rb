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

ActiveRecord::Schema[8.0].define(version: 2025_12_12_024500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "entities", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pinned", default: false, null: false
    t.index ["project_id", "name"], name: "index_entities_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_entities_on_project_id"
  end

  create_table "entity_uploads", force: :cascade do |t|
    t.bigint "entity_id", null: false
    t.bigint "upload_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id", "upload_id"], name: "index_entity_uploads_on_entity_id_and_upload_id", unique: true
    t.index ["entity_id"], name: "index_entity_uploads_on_entity_id"
    t.index ["upload_id"], name: "index_entity_uploads_on_upload_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "uploads", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.string "original_filename", null: false
    t.string "content_type", null: false
    t.bigint "byte_size", null: false
    t.datetime "uploaded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_upload_id"
    t.jsonb "processing_metadata", default: {}, null: false
    t.index ["parent_upload_id"], name: "index_uploads_on_parent_upload_id"
    t.index ["project_id"], name: "index_uploads_on_project_id"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "entities", "projects"
  add_foreign_key "entity_uploads", "entities"
  add_foreign_key "entity_uploads", "uploads"
  add_foreign_key "projects", "users"
  add_foreign_key "uploads", "projects"
  add_foreign_key "uploads", "uploads", column: "parent_upload_id"
  add_foreign_key "uploads", "users"
end
