class ImportBatchesController < ApplicationController
  before_action :set_conversation
  before_action :set_import_batch, only: [:show, :destroy]

  def index
    @import_batches = @conversation.import_batches.recent
  end

  def show
    @new_messages = @import_batch.messages.where("sent_at > ?", previous_import_cutoff)
  end

  def new
    @import_batch = @conversation.import_batches.new
  end

  def create
    @import_batch = @conversation.import_batches.new(import_batch_params)
    @import_batch.filename = params[:import_batch][:file]&.original_filename

    # Calculate file checksum
    if params[:import_batch][:file].present?
      file_content = params[:import_batch][:file].read
      @import_batch.file_checksum = Digest::MD5.hexdigest(file_content)
      params[:import_batch][:file].rewind

      # Check for duplicate
      if @import_batch.duplicate?
        redirect_to conversation_import_batches_path(@conversation),
          alert: "This file has already been imported."
        return
      end
    end

    if @import_batch.save
      # Enqueue background job for processing
      ImportJob.perform_later(@import_batch.id)

      redirect_to conversation_import_batch_path(@conversation, @import_batch),
        notice: "Import started. Processing in background..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @import_batch.destroy
    redirect_to conversation_import_batches_path(@conversation),
      notice: "Import batch deleted successfully."
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def set_import_batch
    @import_batch = @conversation.import_batches.find(params[:id])
  end

  def import_batch_params
    params.require(:import_batch).permit(:file)
  end

  def previous_import_cutoff
    previous = @import_batch.previous_import
    previous&.completed_at || Time.at(0)
  end
end
