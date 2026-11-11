class AnalyticsController < ApplicationController
  before_action :set_conversation

  # Timeline view - full chronological message view
  def timeline
    @messages = @conversation.messages.chronological.includes(:participant, :audio_transcript)
    @messages = @messages.page(params[:page]).per(100) if defined?(Kaminari)
  end

  # Pulse - message volume and engagement metrics
  def pulse
    @engine = AnalyticsEngine.new(@conversation)
    @days = params[:days]&.to_i || 30

    @volume_trend = @engine.message_volume_trend(days: @days)
    @rolling_engagement = @engine.rolling_engagement(window: 7)
    @hourly_heatmap = @engine.hourly_heatmap
  end

  # Shift - sentiment and tone analysis over time
  def shift
    @engine = AnalyticsEngine.new(@conversation)
    @days = params[:days]&.to_i || 30

    @sentiment_trend = @engine.sentiment_trend(days: @days)
    @response_time_trend = @engine.response_time_trend(days: @days)
  end

  # Chapters - conversation phases
  def chapters
    @chapters = @conversation.conversation_chapters.chronological

    if @chapters.empty?
      # Auto-detect chapters
      @chapters = AnalyticsEngine.new(@conversation).detect_conversation_phases
    end
  end

  # New Since Last Import
  def new_since_last
    @latest_import = @conversation.latest_import
    @new_messages = @conversation.new_messages_since_last_import
      .chronological
      .includes(:participant, :audio_transcript)
  end

  # Response Drift - how response patterns change
  def response_drift
    @engine = AnalyticsEngine.new(@conversation)
    @response_times = @engine.avg_response_times_by_participant
    @initiation_trend = @engine.initiation_trend(days: 60)
  end

  # Daily Rhythm - time-of-day patterns
  def daily_rhythm
    @engine = AnalyticsEngine.new(@conversation)
    @hourly_heatmap = @engine.hourly_heatmap

    # Get day of week distribution
    @day_of_week = @conversation.messages.group_by(&:day_of_week)
      .transform_values(&:count)
      .sort_by { |day, _| Date::DAYNAMES.index(day) }
  end

  # Daily Breakdown - detailed view of each day with hour-by-hour breakdown
  def daily_breakdown
    @engine = AnalyticsEngine.new(@conversation)
    @days = params[:days]&.to_i || 30
    @breakdown = @engine.daily_breakdown(days: @days)
  end

  # API endpoint for chart data
  def chart_data
    @engine = AnalyticsEngine.new(@conversation)
    days = params[:days]&.to_i || 30

    data = case params[:chart_type]
           when "sentiment_trend"
             @engine.sentiment_trend(days: days)
           when "message_volume"
             @engine.message_volume_trend(days: days)
           when "response_time"
             @engine.response_time_trend(days: days)
           when "hourly_heatmap"
             @engine.hourly_heatmap
           when "rolling_engagement"
             @engine.rolling_engagement(window: 7)
           else
             { error: "Unknown chart type" }
           end

    render json: data
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
end
