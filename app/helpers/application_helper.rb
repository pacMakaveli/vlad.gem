module ApplicationHelper
  def sentiment_color(score)
    return "text-gray-400" if score.nil?

    if score > 0.2
      "text-green-600"
    elsif score < -0.2
      "text-red-600"
    else
      "text-yellow-600"
    end
  end

  def sentiment_badge_color(label)
    case label
    when "positive"
      "bg-green-100 text-green-800"
    when "negative"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def participant_color(participant)
    # Rotate through a set of border colors
    colors = [
      "border-purple-500",
      "border-blue-500",
      "border-pink-500",
      "border-indigo-500"
    ]

    colors[participant.id % colors.length]
  end

  def format_duration(seconds)
    return "N/A" if seconds.nil? || seconds.zero?

    if seconds < 60
      "#{seconds.round}s"
    elsif seconds < 3600
      "#{(seconds / 60).round}m"
    elsif seconds < 86400
      "#{(seconds / 3600).round(1)}h"
    else
      "#{(seconds / 86400).round(1)}d"
    end
  end

  def format_date_range(start_date, end_date)
    return "N/A" unless start_date && end_date

    if start_date.year == end_date.year
      if start_date.month == end_date.month
        "#{start_date.strftime("%b %d")} - #{end_date.strftime("%d, %Y")}"
      else
        "#{start_date.strftime("%b %d")} - #{end_date.strftime("%b %d, %Y")}"
      end
    else
      "#{start_date.strftime("%b %d, %Y")} - #{end_date.strftime("%b %d, %Y")}"
    end
  end

  # Chart data helpers
  def chart_data_for_volume(trend)
    {
      labels: trend.map { |d| d[:date].strftime("%b %d") },
      datasets: [{
        label: "Messages",
        data: trend.map { |d| d[:messages] },
        borderColor: "rgb(147, 51, 234)",
        backgroundColor: "rgba(147, 51, 234, 0.1)",
        tension: 0.3
      }]
    }
  end

  def chart_data_for_hourly(heatmap)
    {
      labels: heatmap.map { |h| "#{h[:hour]}:00" },
      datasets: [{
        label: "Messages",
        data: heatmap.map { |h| h[:messages] },
        backgroundColor: "rgba(147, 51, 234, 0.6)",
        borderColor: "rgb(147, 51, 234)",
        borderWidth: 1
      }]
    }
  end

  def chart_data_for_rolling(engagement)
    {
      labels: engagement.map { |e| e[:end_date].strftime("%b %d") },
      datasets: [{
        label: "Messages (7-day avg)",
        data: engagement.map { |e| e[:total_messages] },
        borderColor: "rgb(147, 51, 234)",
        backgroundColor: "rgba(147, 51, 234, 0.1)",
        tension: 0.3
      }]
    }
  end

  def chart_data_for_sentiment(trend)
    {
      labels: trend.map { |d| d[:date].strftime("%b %d") },
      datasets: [{
        label: "Sentiment Score",
        data: trend.map { |d| d[:sentiment] },
        borderColor: "rgb(147, 51, 234)",
        backgroundColor: "rgba(147, 51, 234, 0.1)",
        tension: 0.3,
        fill: true
      }]
    }
  end

  def chart_data_for_response_time(trend)
    {
      labels: trend.map { |d| d[:date].strftime("%b %d") },
      datasets: [{
        label: "Avg Response Time (minutes)",
        data: trend.map { |d| (d[:avg_response_time] || 0) / 60.0 },
        borderColor: "rgb(59, 130, 246)",
        backgroundColor: "rgba(59, 130, 246, 0.1)",
        tension: 0.3,
        fill: true
      }]
    }
  end

  def chart_data_for_day_of_week(day_data)
    day_order = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    sorted_data = day_order.map do |day|
      [ day, day_data.find { |d, _| d == day }&.last || 0 ]
    end

    {
      labels: sorted_data.map(&:first),
      datasets: [{
        label: "Messages",
        data: sorted_data.map(&:last),
        backgroundColor: "rgba(59, 130, 246, 0.6)",
        borderColor: "rgb(59, 130, 246)",
        borderWidth: 1
      }]
    }
  end

  def chart_data_for_initiations(trend)
    return {} if trend.empty?

    participant_ids = trend.first[:initiations].keys
    participant_names = Participant.where(id: participant_ids).pluck(:id, :name).to_h

    datasets = participant_ids.map.with_index do |pid, index|
      {
        label: participant_names[pid.to_i] || "Unknown",
        data: trend.map { |t| t[:initiations][pid] || 0 },
        backgroundColor: index.even? ? "rgba(147, 51, 234, 0.6)" : "rgba(59, 130, 246, 0.6)",
        borderColor: index.even? ? "rgb(147, 51, 234)" : "rgb(59, 130, 246)",
        borderWidth: 1
      }
    end

    {
      labels: trend.map { |t| t[:date].strftime("%b %d") },
      datasets: datasets
    }
  end
end
