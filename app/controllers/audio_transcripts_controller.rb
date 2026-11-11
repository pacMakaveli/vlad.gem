class AudioTranscriptsController < ApplicationController
  before_action :set_message
  before_action :set_audio_transcript, only: [:show, :destroy, :retry_transcription]

  def show
  end

  def new
    @audio_transcript = @message.build_audio_transcript
  end

  def create
    @audio_transcript = @message.build_audio_transcript(audio_transcript_params)

    if @audio_transcript.save
      # Enqueue transcription job
      TranscriptionJob.perform_later(@audio_transcript.id)

      redirect_to [@message.conversation, @message],
        notice: "Audio file uploaded. Transcription in progress..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @audio_transcript.destroy
    redirect_to [@message.conversation, @message],
      notice: "Audio transcript deleted successfully."
  end

  def retry_transcription
    if @audio_transcript.failed?
      @audio_transcript.update(status: "pending")
      TranscriptionJob.perform_later(@audio_transcript.id)

      redirect_to [@message.conversation, @message],
        notice: "Retrying transcription..."
    else
      redirect_to [@message.conversation, @message],
        alert: "Can only retry failed transcriptions."
    end
  end

  private

  def set_message
    @message = Message.find(params[:message_id])
  end

  def set_audio_transcript
    @audio_transcript = @message.audio_transcript
  end

  def audio_transcript_params
    params.require(:audio_transcript).permit(:audio_file)
  end
end
