# Import Processor Service
# Handles importing WhatsApp chat exports with intelligent deduplication
#
# Features:
# - Deduplication by content hash
# - Tracks new messages since last import
# - Updates conversation date ranges
# - Creates/finds participants
# - Runs analytics after import
# - Supports ZIP files with chat.txt and media attachments

require "zip"

class ImportProcessor
  attr_reader :import_batch, :conversation, :results

  def initialize(import_batch)
    @import_batch = import_batch
    @conversation = import_batch.conversation
    @results = {
      total_parsed: 0,
      imported: 0,
      skipped: 0,
      new_since_last: 0,
      errors: []
    }
  end

  # Process the import
  def process
    import_batch.start_processing!

    begin
      # Read the file content
      content = read_file_content

      # Parse the content
      parser = WhatsappParser.new(content)
      unless parser.valid?
        raise "Invalid WhatsApp export format"
      end

      parsed_data = parser.parse
      @results[:total_parsed] = parsed_data[:messages].count
      @results[:errors] = parsed_data[:errors]

      # Get the cutoff time for "new" messages
      previous_import = import_batch.previous_import
      new_message_cutoff = previous_import&.completed_at || Time.at(0)

      # Import messages
      ActiveRecord::Base.transaction do
        parsed_data[:messages].each do |msg_data|
          result = import_message(msg_data)

          if result[:imported]
            @results[:imported] += 1

            # Check if this is a new message since last import
            if msg_data[:sent_at] > new_message_cutoff
              @results[:new_since_last] += 1
            end
          else
            @results[:skipped] += 1
          end
        end

        # Update import batch with results
        import_batch.update!(
          total_lines: @results[:total_parsed],
          messages_imported: @results[:imported],
          messages_skipped: @results[:skipped],
          new_messages_count: @results[:new_since_last]
        )
      end

      # Post-import tasks
      conversation.update_date_range!

      # Trigger analytics calculation
      AnalyticsEngine.new(conversation).calculate_daily_metrics

      import_batch.complete!
      @results[:success] = true

    rescue => e
      @results[:success] = false
      @results[:error] = e.message
      import_batch.fail!(e)
      Rails.logger.error("Import failed: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    @results
  end

  private

  def read_file_content
    unless import_batch.file.attached?
      raise "No file attached to import batch"
    end

    filename = import_batch.file.filename.to_s

    # Check if it's a ZIP file
    if filename.end_with?(".zip")
      extract_chat_from_zip
    else
      # Plain text file
      import_batch.file.download
    end
  end

  def extract_chat_from_zip
    chat_content = nil

    import_batch.file.open do |file|
      Zip::File.open(file.path) do |zip_file|
        # Find the chat text file (usually _chat.txt or WhatsApp Chat.txt)
        chat_entry = zip_file.entries.find do |entry|
          entry.name.end_with?("_chat.txt") ||
          entry.name.end_with?("Chat.txt") ||
          entry.name == "chat.txt"
        end

        unless chat_entry
          raise "No chat.txt file found in ZIP archive"
        end

        # Read the chat content
        chat_content = chat_entry.get_input_stream.read

        # TODO: Handle media attachments
        # For now, we'll just extract the text. Media handling can be added later
        # media_entries = zip_file.entries.reject { |e| e.name.end_with?(".txt") }
      end
    end

    chat_content
  end

  def import_message(msg_data)
    # Find or create participant
    participant = conversation.participants.find_or_create_by!(name: msg_data[:sender])

    # Generate content hash for deduplication
    content_hash = generate_content_hash(msg_data)

    # Check if message already exists
    existing_message = conversation.messages.find_by(content_hash: content_hash)

    if existing_message
      # Message already exists, skip
      return { imported: false, message: existing_message, reason: "duplicate" }
    end

    # Create new message
    message = conversation.messages.create!(
      participant: participant,
      import_batch: import_batch,
      sent_at: msg_data[:sent_at],
      content: msg_data[:content],
      message_type: msg_data[:message_type],
      media_type: msg_data[:media_type],
      content_hash: content_hash
    )

    # Analyze sentiment if it's a text message
    if message.message_type == "text" && message.content.present?
      SentimentAnalyzer.new(message).analyze!
    end

    { imported: true, message: message }
  end

  def generate_content_hash(msg_data)
    data = "#{msg_data[:sent_at].to_i}|#{msg_data[:sender]}|#{msg_data[:content]}"
    Digest::SHA256.hexdigest(data)
  end
end
