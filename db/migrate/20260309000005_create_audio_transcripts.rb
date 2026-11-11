class CreateAudioTranscripts < ActiveRecord::Migration[8.1]
  def change
    create_table :audio_transcripts do |t|
      t.references :message, null: false, foreign_key: true
      t.text :transcript_text
      t.string :status, default: "pending" # pending, processing, completed, failed
      t.float :confidence_score
      t.string :language_detected
      t.integer :duration_seconds
      t.string :transcription_service # openai_whisper, google, etc.
      t.text :error_message
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :audio_transcripts, :status
  end
end
