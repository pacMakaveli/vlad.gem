# Sentiment Analysis Service
# Analyzes the sentiment of messages using the Sentimental gem
#
# Usage:
#   analyzer = SentimentAnalyzer.new(message)
#   analyzer.analyze!

class SentimentAnalyzer
  attr_reader :message

  def initialize(message)
    @message = message
    @analyzer = Sentimental.new
    @analyzer.load_defaults
    @analyzer.threshold = 0.1 # Adjust sensitivity
  end

  # Analyze and save sentiment
  def analyze!
    return unless message.content.present?

    # Get the full text including transcript if available
    text = message.full_text

    # Get sentiment score (-1 to 1)
    score = @analyzer.score(text)

    # Get sentiment label
    sentiment = @analyzer.sentiment(text)
    label = case sentiment
            when :positive then "positive"
            when :negative then "negative"
            else "neutral"
            end

    # Update message
    message.update_columns(
      sentiment_score: score,
      sentiment_label: label
    )

    { score: score, label: label }
  end

  # Analyze without saving
  def analyze_text(text)
    score = @analyzer.score(text)
    sentiment = @analyzer.sentiment(text)

    {
      score: score,
      label: sentiment.to_s
    }
  end

  # Batch analyze messages
  def self.analyze_batch(messages)
    messages.find_each do |message|
      new(message).analyze!
    end
  end
end
