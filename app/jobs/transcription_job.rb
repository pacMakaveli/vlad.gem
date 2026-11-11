# Background job for audio transcription
class TranscriptionJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(audio_transcript_id)
    audio_transcript = AudioTranscript.find(audio_transcript_id)
    TranscriptionService.new(audio_transcript).transcribe!
  end
end
