# Audio Transcription Service
# Uses OpenAI Whisper API to transcribe audio files
#
# Usage:
#   service = TranscriptionService.new(audio_transcript)
#   service.transcribe!

class TranscriptionService
  attr_reader :audio_transcript, :client

  def initialize(audio_transcript)
    @audio_transcript = audio_transcript
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  # Transcribe the audio file
  def transcribe!
    audio_transcript.start_transcribing!

    begin
      unless audio_transcript.audio_file.attached?
        raise "No audio file attached"
      end

      # Download the audio file to a temporary location
      temp_file = download_audio_file

      # Call OpenAI Whisper API
      response = @client.audio.transcribe(
        parameters: {
          model: "whisper-1",
          file: temp_file
        }
      )

      # Extract transcript and metadata
      transcript_text = response.dig("text")
      language = response.dig("language")

      # Get audio duration if available
      duration = extract_audio_duration(temp_file)

      # Complete the transcription
      audio_transcript.complete!(
        transcript_text,
        {
          language: language,
          duration: duration,
          confidence: 0.95 # Whisper doesn't provide confidence scores
        }
      )

      # Update the message with sentiment analysis
      if audio_transcript.message
        SentimentAnalyzer.new(audio_transcript.message).analyze!
      end

      { success: true, transcript: transcript_text }

    rescue => e
      audio_transcript.fail!(e)
      Rails.logger.error("Transcription failed: #{e.message}")
      { success: false, error: e.message }

    ensure
      # Clean up temp file
      temp_file&.close
      temp_file&.unlink if temp_file&.path && File.exist?(temp_file.path)
    end
  end

  private

  def download_audio_file
    # Create a temporary file with the correct extension
    extension = File.extname(audio_transcript.audio_file.filename.to_s)
    temp_file = Tempfile.new([ "audio", extension ])

    # Download the audio file
    audio_transcript.audio_file.download do |chunk|
      temp_file.write(chunk)
    end

    temp_file.rewind
    temp_file
  end

  def extract_audio_duration(file)
    # This is a simple implementation
    # In production, you might want to use ffmpeg or similar
    # For now, return nil and let it be set later if needed
    nil
  rescue
    nil
  end
end
