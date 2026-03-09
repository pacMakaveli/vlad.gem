# WhatsApp Export Parser
# Parses exported WhatsApp chat files
#
# Expected format:
# [02/03/2026, 21:15] Vlad: Hello
# [02/03/2026, 21:16] Gemma: Hi!
# [02/03/2026, 21:17] Vlad: How was your day?
#
# Also handles:
# - Multi-line messages
# - Media placeholders: <Media omitted>
# - System messages: "Messages and calls are end-to-end encrypted"
# - Deleted messages: "This message was deleted"

class WhatsappParser
  # Match pattern: [DD/MM/YYYY, HH:MM] Name: Message
  MESSAGE_REGEX = /^\[(\d{2}\/\d{2}\/\d{4}),\s(\d{2}:\d{2})\]\s([^:]+):\s(.*)$/

  attr_reader :content, :errors

  def initialize(content)
    @content = content
    @errors = []
  end

  # Parse the content and return structured data
  def parse
    return { messages: [], errors: @errors } if @content.blank?

    messages = []
    current_message = nil

    @content.each_line.with_index do |line, index|
      line = line.strip

      # Skip empty lines
      next if line.empty?

      if matches_message_format?(line)
        # Save previous message if exists
        messages << current_message if current_message

        # Start new message
        current_message = parse_message_line(line, index + 1)
      elsif current_message
        # This is a continuation of the previous message (multi-line)
        current_message[:content] << "\n#{line}"
      else
        # Line doesn't match format and we don't have a current message
        @errors << "Line #{index + 1}: Invalid format - #{line.first(50)}"
      end
    end

    # Don't forget the last message
    messages << current_message if current_message

    { messages: messages, errors: @errors }
  end

  # Quick validation without full parse
  def valid?
    return false if @content.blank?

    # Check if at least one line matches the expected format
    @content.lines.any? { |line| matches_message_format?(line) }
  end

  # Get participant names from the content
  def participants
    names = Set.new

    @content.each_line do |line|
      if match = line.match(MESSAGE_REGEX)
        names << match[3].strip
      end
    end

    names.to_a
  end

  private

  def matches_message_format?(line)
    line.match?(MESSAGE_REGEX)
  end

  def parse_message_line(line, line_number)
    match = line.match(MESSAGE_REGEX)
    return nil unless match

    date_str = match[1] # DD/MM/YYYY
    time_str = match[2] # HH:MM
    sender = match[3].strip
    content = match[4].strip

    # Parse datetime
    begin
      datetime = DateTime.strptime("#{date_str} #{time_str}", "%d/%m/%Y %H:%M")
    rescue ArgumentError => e
      @errors << "Line #{line_number}: Invalid date/time format - #{e.message}"
      datetime = Time.current
    end

    # Detect message type
    message_type, media_type = detect_message_type(content)

    {
      sent_at: datetime,
      sender: sender,
      content: content,
      message_type: message_type,
      media_type: media_type,
      line_number: line_number
    }
  end

  def detect_message_type(content)
    case content
    when /^<Media omitted>$/
      [ "media", "unknown" ]
    when /^image omitted$/i
      [ "media", "image" ]
    when /^video omitted$/i
      [ "media", "video" ]
    when /^audio omitted$/i
      [ "media", "audio" ]
    when /^sticker omitted$/i
      [ "media", "sticker" ]
    when /^GIF omitted$/i
      [ "media", "gif" ]
    when /^document omitted$/i
      [ "media", "document" ]
    when /^This message was deleted$/i
      [ "deleted", nil ]
    when /Messages and calls are end-to-end encrypted/i
      [ "system", nil ]
    when /created group/i
      [ "system", nil ]
    when /changed the subject/i
      [ "system", nil ]
    when /left$/i
      [ "system", nil ]
    when /joined using this group's invite link/i
      [ "system", nil ]
    else
      [ "text", nil ]
    end
  end
end
