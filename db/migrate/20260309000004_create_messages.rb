class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.references :import_batch, null: false, foreign_key: true

      t.datetime :sent_at, null: false
      t.text :content
      t.string :message_type, default: "text" # text, media, system, audio, deleted
      t.string :media_type # image, video, audio, document, sticker, gif
      t.string :content_hash # SHA256 hash for deduplication

      # Analytics fields
      t.integer :character_count, default: 0
      t.integer :word_count, default: 0
      t.float :sentiment_score # -1.0 (negative) to 1.0 (positive)
      t.string :sentiment_label # negative, neutral, positive
      t.integer :emoji_count, default: 0
      t.json :emojis, default: [] # Array of emojis used

      # Response tracking
      t.references :in_response_to, foreign_key: { to_table: :messages }
      t.integer :response_time_seconds # Time to respond to previous message

      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :messages, :sent_at
    add_index :messages, :message_type
    add_index :messages, [:conversation_id, :sent_at]
    add_index :messages, [:conversation_id, :content_hash], unique: true, name: "index_messages_on_conversation_and_hash"
    add_index :messages, :sentiment_score
  end
end
