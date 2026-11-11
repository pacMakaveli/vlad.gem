class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :participant
  belongs_to :import_batch
  belongs_to :in_response_to, class_name: "Message", optional: true
  has_many :responses, class_name: "Message", foreign_key: :in_response_to_id, dependent: :nullify
  has_one :audio_transcript, dependent: :destroy

  validates :sent_at, presence: true
  validates :message_type, inclusion: { in: %w[text media system audio deleted] }

  scope :chronological, -> { order(:sent_at) }
  scope :reverse_chronological, -> { order(sent_at: :desc) }
  scope :text_messages, -> { where(message_type: "text") }
  scope :media_messages, -> { where(message_type: "media") }
  scope :audio_messages, -> { where(message_type: "audio") }
  scope :on_date, ->(date) { where("DATE(sent_at) = ?", date) }
  scope :in_date_range, ->(start_date, end_date) {
    where(sent_at: start_date.beginning_of_day..end_date.end_of_day)
  }

  before_save :calculate_metrics
  after_create :update_response_time

  # Generate content hash for deduplication
  def generate_content_hash
    data = "#{sent_at.to_i}|#{participant_id}|#{content}"
    Digest::SHA256.hexdigest(data)
  end

  # Calculate message metrics
  def calculate_metrics
    return unless content.present?

    self.character_count = content.length
    self.word_count = content.split.size
    self.emoji_count = content.scan(/[\p{Emoji}]/).size
    self.emojis = content.scan(/[\p{Emoji}]/).uniq
    self.content_hash ||= generate_content_hash
  end

  # Update response time based on previous message
  def update_response_time
    return unless participant.present?

    # Find the most recent message from a different participant
    previous_message = conversation.messages
      .where.not(participant_id: participant_id)
      .where("sent_at < ?", sent_at)
      .order(sent_at: :desc)
      .first

    if previous_message
      time_diff = (sent_at - previous_message.sent_at).to_i
      update_columns(
        in_response_to_id: previous_message.id,
        response_time_seconds: time_diff
      )
    end
  end

  # Get the hour of day (0-23)
  def hour_of_day
    sent_at.hour
  end

  # Get the day of week
  def day_of_week
    sent_at.strftime("%A")
  end

  # Check if this message is an emoji-only message
  def emoji_only?
    return false unless content.present?
    content.gsub(/[\p{Emoji}\s]/, "").empty?
  end

  # Get full text including transcript
  def full_text
    parts = [ content ]
    parts << audio_transcript.transcript_text if audio_transcript&.transcript_text.present?
    parts.compact.join("\n")
  end
end
