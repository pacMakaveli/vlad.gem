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
end
