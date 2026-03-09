# Analytics Engine
# Calculates and aggregates conversation analytics
#
# Usage:
#   engine = AnalyticsEngine.new(conversation)
#   engine.calculate_daily_metrics
#   engine.response_time_trend
#   engine.sentiment_trend

class AnalyticsEngine
  attr_reader :conversation

  def initialize(conversation)
    @conversation = conversation
  end

  # Calculate daily metrics for all days in the conversation
  def calculate_daily_metrics
    return unless conversation.first_message_at && conversation.last_message_at

    start_date = conversation.first_message_at.to_date
    end_date = conversation.last_message_at.to_date

    DailyMetric.recalculate_range(conversation, start_date, end_date)
  end

  # Get response time trend over time
  def response_time_trend(days: 30)
    end_date = Date.today
    start_date = end_date - days.days

    conversation.daily_metrics
      .in_range(start_date, end_date)
      .chronological
      .pluck(:metric_date, :avg_response_time_seconds)
      .map { |date, seconds| { date: date, avg_response_time: seconds } }
  end

  # Get sentiment trend over time
  def sentiment_trend(days: 30)
    end_date = Date.today
    start_date = end_date - days.days

    conversation.daily_metrics
      .in_range(start_date, end_date)
      .chronological
      .pluck(:metric_date, :avg_sentiment_score)
      .map { |date, score| { date: date, sentiment: score } }
  end

  # Get message volume trend
  def message_volume_trend(days: 30)
    end_date = Date.today
    start_date = end_date - days.days

    conversation.daily_metrics
      .in_range(start_date, end_date)
      .chronological
      .pluck(:metric_date, :total_messages)
      .map { |date, count| { date: date, messages: count } }
  end

  # Get hourly heatmap data
  def hourly_heatmap
    # Aggregate messages by hour of day across all days
    hours_data = Array.new(24, 0)

    conversation.messages.find_each do |message|
      hours_data[message.hour_of_day] += 1
    end

    (0..23).map do |hour|
      { hour: hour, messages: hours_data[hour] }
    end
  end

  # Get conversation initiations over time
  def initiation_trend(days: 30)
    end_date = Date.today
    start_date = end_date - days.days

    conversation.daily_metrics
      .in_range(start_date, end_date)
      .chronological
      .select(:metric_date, :initiations_by_participant)
      .map do |metric|
        {
          date: metric.metric_date,
          initiations: metric.initiations_by_participant
        }
      end
  end

  # Calculate who responds faster on average
  def avg_response_times_by_participant
    conversation.participants.map do |participant|
      # Get messages from this participant that are responses
      avg_time = participant.messages
        .where.not(response_time_seconds: nil)
        .average(:response_time_seconds)&.to_f || 0

      {
        participant: participant.name,
        avg_response_time: avg_time,
        avg_response_time_formatted: format_duration(avg_time)
      }
    end
  end

  # Get top emoji usage
  def top_emojis(limit: 20)
    emoji_counts = Hash.new(0)

    conversation.messages.where("emoji_count > 0").find_each do |message|
      message.emojis.each { |emoji| emoji_counts[emoji] += 1 }
    end

    emoji_counts.sort_by { |_emoji, count| -count }
      .first(limit)
      .map { |emoji, count| { emoji: emoji, count: count } }
  end

  # Detect conversation patterns/phases
  def detect_conversation_phases
    ConversationChapter.auto_detect_chapters(conversation)
  end

  # Get conversation summary stats
  def summary_stats
    days = if conversation.first_message_at && conversation.last_message_at
      ((conversation.last_message_at - conversation.first_message_at) / 1.day).to_i
    else
      0
    end

    {
      total_messages: conversation.total_messages_count,
      date_range: {
        start: conversation.first_message_at,
        end: conversation.last_message_at,
        days: days
      },
      participants: conversation.participants.map do |p|
        total_count = conversation.total_messages_count
        percentage = total_count > 0 ? (p.messages.count.to_f / total_count * 100).round(1) : 0

        {
          name: p.name,
          message_count: p.messages.count,
          percentage: percentage
        }
      end,
      avg_sentiment: conversation.messages.where.not(sentiment_score: nil)
        .average(:sentiment_score)&.to_f,
      total_words: conversation.messages.sum(:word_count),
      avg_messages_per_day: calculate_avg_messages_per_day,
      most_active_day: find_most_active_day
    }
  end

  # Get rolling 7-day engagement
  def rolling_engagement(window: 7)
    all_dates = conversation.daily_metrics.chronological.pluck(:metric_date)
    return [] if all_dates.empty?

    all_dates.each_cons(window).map do |date_window|
      end_date = date_window.last
      start_date = date_window.first

      metrics = conversation.daily_metrics.in_range(start_date, end_date)

      {
        end_date: end_date,
        total_messages: metrics.sum(:total_messages),
        avg_sentiment: metrics.average(:avg_sentiment_score)&.to_f,
        avg_response_time: metrics.average(:avg_response_time_seconds)&.to_f
      }
    end
  end

  # Compare two time periods
  def compare_periods(period1_start, period1_end, period2_start, period2_end)
    period1 = calculate_period_stats(period1_start, period1_end)
    period2 = calculate_period_stats(period2_start, period2_end)

    {
      period1: period1,
      period2: period2,
      changes: {
        messages: calculate_change(period1[:total_messages], period2[:total_messages]),
        sentiment: calculate_change(period1[:avg_sentiment], period2[:avg_sentiment]),
        response_time: calculate_change(period1[:avg_response_time], period2[:avg_response_time])
      }
    }
  end

  private

  def calculate_avg_messages_per_day
    return 0 unless conversation.first_message_at && conversation.last_message_at

    total_days = ((conversation.last_message_at - conversation.first_message_at) / 1.day).to_i + 1
    (conversation.total_messages_count.to_f / total_days).round(2)
  end

  def find_most_active_day
    conversation.daily_metrics
      .order(total_messages: :desc)
      .first
      &.metric_date
  end

  def calculate_period_stats(start_date, end_date)
    metrics = conversation.daily_metrics.in_range(start_date, end_date)

    {
      total_messages: metrics.sum(:total_messages),
      avg_sentiment: metrics.average(:avg_sentiment_score)&.to_f,
      avg_response_time: metrics.average(:avg_response_time_seconds)&.to_f,
      days: (end_date - start_date).to_i + 1
    }
  end

  def calculate_change(old_value, new_value)
    return nil if old_value.nil? || new_value.nil? || old_value.zero?

    ((new_value - old_value) / old_value * 100).round(2)
  end

  def format_duration(seconds)
    return "N/A" if seconds.nil? || seconds.zero?

    if seconds < 60
      "#{seconds.round}s"
    elsif seconds < 3600
      "#{(seconds / 60).round}m"
    else
      "#{(seconds / 3600).round(1)}h"
    end
  end
end
