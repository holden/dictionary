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

ActiveRecord::Schema[8.0].define(version: 2024_12_23_212849) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

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

  create_table "topic_relationships", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "related_topic_id", null: false
    t.string "relationship_type", null: false
    t.float "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_topic_id"], name: "index_topic_relationships_on_related_topic_id"
    t.index ["topic_id", "related_topic_id", "relationship_type"], name: "index_topic_relationships_uniqueness", unique: true
    t.index ["topic_id"], name: "index_topic_relationships_on_topic_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "type", null: false
    t.string "title", null: false
    t.integer "part_of_speech", default: 0, null: false
    t.string "conceptnet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conceptnet_id"], name: "index_topics_on_conceptnet_id", unique: true, where: "(conceptnet_id IS NOT NULL)"
    t.index ["part_of_speech"], name: "index_topics_on_part_of_speech"
    t.index ["title"], name: "index_topics_on_title", unique: true
    t.index ["title"], name: "index_topics_on_title_pattern", opclass: :gin_trgm_ops, using: :gin
    t.index ["type"], name: "index_topics_on_type"
    t.check_constraint "part_of_speech >= 0 AND part_of_speech <= 4", name: "valid_part_of_speech"
    t.check_constraint "type::text = ANY (ARRAY['Person'::character varying, 'Place'::character varying, 'Concept'::character varying, 'Thing'::character varying, 'Event'::character varying, 'Action'::character varying, 'Other'::character varying]::text[])", name: "valid_topic_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "topic_relationships", "topics"
  add_foreign_key "topic_relationships", "topics", column: "related_topic_id"
end
