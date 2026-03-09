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

ActiveRecord::Schema[8.1].define(version: 2026_03_09_000007) do
  create_table "audio_transcripts", force: :cascade do |t|
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.text "error_message"
    t.string "language_detected"
    t.integer "message_id", null: false
    t.json "metadata", default: {}
    t.string "status", default: "pending"
    t.text "transcript_text"
    t.string "transcription_service"
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_audio_transcripts_on_message_id"
    t.index ["status"], name: "index_audio_transcripts_on_status"
  end

  create_table "conversation_chapters", force: :cascade do |t|
    t.float "avg_sentiment"
    t.json "characteristics", default: {}
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "detection_method", default: "auto"
    t.string "dominant_theme"
    t.date "end_date", null: false
    t.integer "message_count", default: 0
    t.date "start_date", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "start_date"], name: "index_conversation_chapters_on_conversation_id_and_start_date"
    t.index ["conversation_id"], name: "index_conversation_chapters_on_conversation_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "first_message_at"
    t.datetime "last_message_at"
    t.json "metadata", default: {}
    t.string "title", null: false
    t.integer "total_messages_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["first_message_at"], name: "index_conversations_on_first_message_at"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
  end

  create_table "daily_metrics", force: :cascade do |t|
    t.integer "audio_messages", default: 0
    t.float "avg_response_time_seconds"
    t.float "avg_sentiment_score"
    t.integer "conversation_id", null: false
    t.integer "conversation_initiations", default: 0
    t.datetime "created_at", null: false
    t.json "initiations_by_participant", default: {}
    t.integer "media_messages", default: 0
    t.json "messages_by_hour", default: {}
    t.json "messages_by_participant", default: {}
    t.json "metadata", default: {}
    t.date "metric_date", null: false
    t.json "sentiment_distribution", default: {}
    t.json "top_emojis", default: []
    t.integer "total_characters", default: 0
    t.integer "total_emojis", default: 0
    t.integer "total_messages", default: 0
    t.integer "total_words", default: 0
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "metric_date"], name: "index_daily_metrics_on_conversation_and_date", unique: true
    t.index ["conversation_id"], name: "index_daily_metrics_on_conversation_id"
    t.index ["metric_date"], name: "index_daily_metrics_on_metric_date"
  end

  create_table "import_batches", force: :cascade do |t|
    t.datetime "completed_at"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "file_checksum"
    t.string "filename"
    t.integer "messages_imported", default: 0
    t.integer "messages_skipped", default: 0
    t.json "metadata", default: {}
    t.integer "new_messages_count", default: 0
    t.datetime "started_at"
    t.string "status", default: "pending"
    t.integer "total_lines", default: 0
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_import_batches_on_conversation_id"
    t.index ["created_at"], name: "index_import_batches_on_created_at"
    t.index ["file_checksum"], name: "index_import_batches_on_file_checksum"
    t.index ["status"], name: "index_import_batches_on_status"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "character_count", default: 0
    t.text "content"
    t.string "content_hash"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "emoji_count", default: 0
    t.json "emojis", default: []
    t.integer "import_batch_id", null: false
    t.integer "in_response_to_id"
    t.string "media_type"
    t.string "message_type", default: "text"
    t.json "metadata", default: {}
    t.integer "participant_id", null: false
    t.integer "response_time_seconds"
    t.datetime "sent_at", null: false
    t.string "sentiment_label"
    t.float "sentiment_score"
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0
    t.index ["conversation_id", "content_hash"], name: "index_messages_on_conversation_and_hash", unique: true
    t.index ["conversation_id", "sent_at"], name: "index_messages_on_conversation_id_and_sent_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["import_batch_id"], name: "index_messages_on_import_batch_id"
    t.index ["in_response_to_id"], name: "index_messages_on_in_response_to_id"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["participant_id"], name: "index_messages_on_participant_id"
    t.index ["sent_at"], name: "index_messages_on_sent_at"
    t.index ["sentiment_score"], name: "index_messages_on_sentiment_score"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "messages_count", default: 0
    t.json "metadata", default: {}
    t.string "name", null: false
    t.string "participant_type", default: "user"
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "name"], name: "index_participants_on_conversation_id_and_name", unique: true
    t.index ["conversation_id"], name: "index_participants_on_conversation_id"
  end

  add_foreign_key "audio_transcripts", "messages"
  add_foreign_key "conversation_chapters", "conversations"
  add_foreign_key "daily_metrics", "conversations"
  add_foreign_key "import_batches", "conversations"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "import_batches"
  add_foreign_key "messages", "messages", column: "in_response_to_id"
  add_foreign_key "messages", "participants"
  add_foreign_key "participants", "conversations"
end
