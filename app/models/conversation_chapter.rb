class ConversationChapter < ApplicationRecord
  belongs_to :conversation

  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :chronological, -> { order(:start_date) }
  scope :auto_detected, -> { where(detection_method: "auto") }
  scope :manual, -> { where(detection_method: "manual") }

  # Get messages in this chapter
  def messages
    conversation.messages.in_date_range(start_date, end_date)
  end

  # Calculate chapter statistics
  def calculate_stats!
    chapter_messages = messages

    self.message_count = chapter_messages.count
    self.avg_sentiment = chapter_messages.where.not(sentiment_score: nil)
      .average(:sentiment_score)&.to_f

    # Detect dominant characteristics
    self.characteristics = {
      avg_messages_per_day: (message_count.to_f / days_duration).round(2),
      total_words: chapter_messages.sum(:word_count),
      avg_response_time: chapter_messages.where.not(response_time_seconds: nil)
        .average(:response_time_seconds)&.to_f,
      emoji_usage: chapter_messages.sum(:emoji_count)
    }

    save!
  end

  # Auto-detect chapters based on conversation gaps
  def self.auto_detect_chapters(conversation, gap_days: 7)
    messages = conversation.messages.chronological
    return [] if messages.empty?

    chapters = []
    chapter_start = messages.first.sent_at.to_date
    previous_date = chapter_start

    messages.each do |message|
      current_date = message.sent_at.to_date

      # If there's a significant gap, create a new chapter
      if (current_date - previous_date).to_i > gap_days
        chapters << create(
          conversation: conversation,
          start_date: chapter_start,
          end_date: previous_date,
          detection_method: "auto"
        )

        chapter_start = current_date
      end

      previous_date = current_date
    end

    # Add the final chapter
    chapters << create(
      conversation: conversation,
      start_date: chapter_start,
      end_date: messages.last.sent_at.to_date,
      detection_method: "auto"
    )

    # Calculate stats for each chapter
    chapters.each(&:calculate_stats!)

    chapters
  end

  private

  def days_duration
    (end_date - start_date).to_i + 1
  end

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
