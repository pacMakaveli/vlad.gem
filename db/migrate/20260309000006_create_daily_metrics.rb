class CreateDailyMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_metrics do |t|
      t.references :conversation, null: false, foreign_key: true
      t.date :metric_date, null: false

      # Message counts
      t.integer :total_messages, default: 0
      t.json :messages_by_participant, default: {} # { participant_id => count }

      # Engagement metrics
      t.float :avg_response_time_seconds
      t.integer :total_words, default: 0
      t.integer :total_characters, default: 0

      # Sentiment metrics
      t.float :avg_sentiment_score
      t.json :sentiment_distribution, default: {} # { negative: 0, neutral: 0, positive: 0 }

      # Communication patterns
      t.integer :conversation_initiations, default: 0 # Messages after > 1 hour gap
      t.json :initiations_by_participant, default: {}
      t.integer :total_emojis, default: 0
      t.json :top_emojis, default: []

      # Time distribution
      t.json :messages_by_hour, default: {} # { "0" => 5, "1" => 2, ... }

      # Audio/media
      t.integer :audio_messages, default: 0
      t.integer :media_messages, default: 0

      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :daily_metrics, [:conversation_id, :metric_date], unique: true, name: "index_daily_metrics_on_conversation_and_date"
    add_index :daily_metrics, :metric_date
  end
end
