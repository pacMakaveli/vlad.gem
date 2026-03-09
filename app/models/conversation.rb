class Conversation < ApplicationRecord
  has_many :participants, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :import_batches, dependent: :destroy
  has_many :daily_metrics, dependent: :destroy
  has_many :conversation_chapters, dependent: :destroy

  validates :title, presence: true

  # Get the latest import batch
  def latest_import
    import_batches.order(created_at: :desc).first
  end

  # Get new messages since last import
  def new_messages_since_last_import
    return messages.none unless latest_import&.completed_at

    previous_import = import_batches
      .where.not(id: latest_import.id)
      .where(status: "completed")
      .order(created_at: :desc)
      .first

    return messages if previous_import.nil?

    messages.where("sent_at > ?", previous_import.completed_at)
  end

  # Update conversation date range
  def update_date_range!
    first_msg = messages.order(:sent_at).first
    last_msg = messages.order(:sent_at).last

    update(
      first_message_at: first_msg&.sent_at,
      last_message_at: last_msg&.sent_at,
      total_messages_count: messages.count
    )
  end

  # Get participant by name
  def participant_by_name(name)
    participants.find_by(name: name)
  end
end
