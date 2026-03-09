class DailyMetric < ApplicationRecord
  belongs_to :conversation

  validates :metric_date, presence: true
  validates :metric_date, uniqueness: { scope: :conversation_id }

  scope :chronological, -> { order(:metric_date) }
  scope :reverse_chronological, -> { order(metric_date: :desc) }
  scope :in_range, ->(start_date, end_date) {
    where(metric_date: start_date..end_date)
  }

  # Calculate metrics for a specific date
  def self.calculate_for_date(conversation, date)
    messages = conversation.messages.on_date(date)

    return nil if messages.empty?

    metric = find_or_initialize_by(
      conversation: conversation,
      metric_date: date
    )

    # Message counts
    metric.total_messages = messages.count
    metric.messages_by_participant = messages.group(:participant_id).count

    # Engagement metrics
    metric.avg_response_time_seconds = messages.where.not(response_time_seconds: nil)
      .average(:response_time_seconds)&.to_f

    metric.total_words = messages.sum(:word_count)
    metric.total_characters = messages.sum(:character_count)

    # Sentiment metrics
    sentiment_messages = messages.where.not(sentiment_score: nil)
    metric.avg_sentiment_score = sentiment_messages.average(:sentiment_score)&.to_f

    metric.sentiment_distribution = {
      negative: messages.where(sentiment_label: "negative").count,
      neutral: messages.where(sentiment_label: "neutral").count,
      positive: messages.where(sentiment_label: "positive").count
    }

    # Conversation initiations (messages after > 1 hour gap)
    initiations = count_initiations(messages)
    metric.conversation_initiations = initiations[:total]
    metric.initiations_by_participant = initiations[:by_participant]

    # Emojis
    metric.total_emojis = messages.sum(:emoji_count)
    metric.top_emojis = calculate_top_emojis(messages)

    # Time distribution
    metric.messages_by_hour = messages.group_by(&:hour_of_day)
      .transform_values(&:count)

    # Media counts
    metric.audio_messages = messages.audio_messages.count
    metric.media_messages = messages.media_messages.count

    metric.save!
    metric
  end

  # Recalculate metrics for a date range
  def self.recalculate_range(conversation, start_date, end_date)
    (start_date..end_date).each do |date|
      calculate_for_date(conversation, date)
    end
  end

  private

  def self.count_initiations(messages)
    initiations = { total: 0, by_participant: Hash.new(0) }
    previous_message = nil

    messages.chronological.each do |message|
      if previous_message.nil? || (message.sent_at - previous_message.sent_at) > 1.hour
        initiations[:total] += 1
        initiations[:by_participant][message.participant_id] += 1
      end
      previous_message = message
    end

    initiations
  end

  def self.calculate_top_emojis(messages, limit = 10)
    emoji_counts = Hash.new(0)

    messages.where("emoji_count > 0").find_each do |message|
      message.emojis.each { |emoji| emoji_counts[emoji] += 1 }
    end

    emoji_counts.sort_by { |_emoji, count| -count }.first(limit).map do |emoji, count|
      { emoji: emoji, count: count }
    end
  end
end
