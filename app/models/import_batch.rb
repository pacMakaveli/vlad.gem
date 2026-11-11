class ImportBatch < ApplicationRecord
  belongs_to :conversation
  has_many :messages, dependent: :nullify
  has_one_attached :file

  validates :filename, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }

  # State transitions
  def start_processing!
    update!(status: "processing", started_at: Time.current)
  end

  def complete!
    update!(status: "completed", completed_at: Time.current)
  end

  def fail!(error)
    update!(
      status: "failed",
      completed_at: Time.current,
      error_message: error.message
    )
  end

  # Get the previous successful import
  def previous_import
    conversation.import_batches
      .where(status: "completed")
      .where("created_at < ?", created_at)
      .order(created_at: :desc)
      .first
  end

  # Check if this is a duplicate import
  def duplicate?
    conversation.import_batches
      .where.not(id: id)
      .exists?(file_checksum: file_checksum)
  end
end
