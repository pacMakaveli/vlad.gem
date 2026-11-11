class AudioTranscript < ApplicationRecord
  belongs_to :message
  has_one_attached :audio_file

  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }

  # Start transcription
  def start_transcribing!
    update!(status: "processing")
  end

  # Complete transcription
  def complete!(transcript, metadata = {})
    update!(
      status: "completed",
      transcript_text: transcript,
      confidence_score: metadata[:confidence],
      language_detected: metadata[:language],
      duration_seconds: metadata[:duration]
    )
  end

  # Fail transcription
  def fail!(error)
    update!(
      status: "failed",
      error_message: error.message
    )
  end
end
