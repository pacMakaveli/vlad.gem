class Participant < ApplicationRecord
  belongs_to :conversation
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :conversation_id }

  # Calculate statistics
  def total_messages
    messages.count
  end

  def avg_message_length
    messages.average(:character_count)&.to_f || 0
  end

  def avg_sentiment
    messages.where.not(sentiment_score: nil).average(:sentiment_score)&.to_f
  end

  def most_used_emojis(limit = 10)
    emoji_counts = Hash.new(0)

    messages.where("emojis IS NOT NULL AND emojis != '[]'").find_each do |message|
      message.emojis.each { |emoji| emoji_counts[emoji] += 1 }
    end

    emoji_counts.sort_by { |_emoji, count| -count }.first(limit).to_h
  end
end
