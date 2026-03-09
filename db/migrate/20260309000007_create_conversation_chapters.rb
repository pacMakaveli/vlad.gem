class CreateConversationChapters < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_chapters do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :message_count, default: 0
      t.float :avg_sentiment
      t.string :dominant_theme # detected or manually set
      t.json :characteristics, default: {} # engagement_level, tone, key_topics
      t.string :detection_method, default: "auto" # auto, manual

      t.timestamps
    end

    add_index :conversation_chapters, [:conversation_id, :start_date]
  end
end
