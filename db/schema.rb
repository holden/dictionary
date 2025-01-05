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

ActiveRecord::Schema[8.0].define(version: 2025_01_04_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "author_id"
    t.string "open_library_id"
    t.date "published_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["open_library_id"], name: "index_books_on_open_library_id", unique: true, where: "(open_library_id IS NOT NULL)"
  end

  create_table "definitions", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.string "author_type"
    t.bigint "author_id"
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "idx_definitions_author"
    t.index ["author_type", "author_id"], name: "index_definitions_on_author"
    t.index ["source_type", "source_id"], name: "idx_definitions_source"
    t.index ["source_type", "source_id"], name: "index_definitions_on_source"
    t.index ["topic_id"], name: "index_definitions_on_topic_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "author_id"
    t.string "attribution_text"
    t.string "source_url"
    t.text "original_text"
    t.string "original_language"
    t.text "citation"
    t.boolean "disputed", default: false
    t.boolean "misattributed", default: false
    t.bigint "user_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_quotes_on_author_id"
    t.index ["topic_id"], name: "index_quotes_on_topic_id"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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
    t.string "title", null: false
    t.string "type", null: false
    t.string "concept_net_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.tsvector "tsv"
    t.string "open_library_id"
    t.index ["concept_net_id"], name: "index_topics_on_concept_net_id", unique: true, where: "(concept_net_id IS NOT NULL)"
    t.index ["open_library_id"], name: "index_topics_on_open_library_id"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
    t.index ["title"], name: "index_topics_on_title", unique: true
    t.index ["tsv"], name: "topics_tsv_idx", using: :gin
    t.index ["type"], name: "index_topics_on_type"
    t.check_constraint "type::text = ANY (ARRAY['Person'::character varying::text, 'Place'::character varying::text, 'Concept'::character varying::text, 'Thing'::character varying::text, 'Event'::character varying::text, 'Action'::character varying::text, 'Other'::character varying::text])", name: "valid_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "websites", force: :cascade do |t|
    t.string "url", null: false
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_websites_on_url", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "books", "topics", column: "author_id"
  add_foreign_key "definitions", "topics"
  add_foreign_key "quotes", "topics"
  add_foreign_key "quotes", "topics", column: "author_id"
  add_foreign_key "quotes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "topic_relationships", "topics"
  add_foreign_key "topic_relationships", "topics", column: "related_topic_id"
end
