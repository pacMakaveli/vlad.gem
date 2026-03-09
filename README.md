# Vlad's Gem 💎

**Relationship Conversation Intelligence, Built from Chat Exports**

A personal analytics web app for analyzing WhatsApp conversation exports. Built for fun and insight, not production deployment.

## What It Does

Vlad's Gem takes exported WhatsApp chat files and transforms them into rich, longitudinal conversation analytics. It's designed to help you understand your conversation patterns, sentiment shifts, and engagement trends over time.

### Core Features

- **Smart Import System**: Upload full WhatsApp exports repeatedly without duplicating messages
- **Historical Tracking**: Preserves conversation timeline across multiple imports
- **Deduplication**: Automatically detects and skips duplicate messages
- **Audio Transcription**: Upload and transcribe audio messages using OpenAI Whisper
- **Sentiment Analysis**: Automatic tone and sentiment detection for every message
- **Rich Analytics**: Multiple analytical views of your conversation data

### Analytics Views

1. **Timeline** - Full chronological message view
2. **Pulse** - Message volume and engagement metrics
3. **Shift** - Sentiment and tone analysis over time
4. **Chapters** - Auto-detected conversation phases
5. **New Since Last Import** - See what changed in the latest import
6. **Response Drift** - How response patterns evolve
7. **Daily Rhythm** - Time-of-day and day-of-week patterns

## Tech Stack

- **Ruby on Rails 8.1** - Modern Rails with all the good stuff
- **SQLite** - Simple, file-based database for local development
- **PostgreSQL** - Production database (configured but optional for local dev)
- **Stimulus + Turbo** - Hotwire for reactive UI
- **Chart.js** - Beautiful, responsive charts
- **Tailwind CSS** - Utility-first styling
- **Sidekiq** - Background job processing
- **OpenAI Whisper** - Audio transcription (via ruby-openai gem)
- **Sentimental** - Sentiment analysis

## Architecture Highlights

### Models

- `Conversation` - The chat between two people
- `Participant` - People in the conversation
- `ImportBatch` - Tracks each full export upload with checksums
- `Message` - Individual messages with content hashing for deduplication
- `AudioTranscript` - Transcribed audio with metadata
- `DailyMetric` - Pre-computed daily analytics for performance
- `ConversationChapter` - Auto-detected conversation phases

### Services

- `WhatsappParser` - Parses WhatsApp export format (handles multi-line, media, system messages)
- `ImportProcessor` - Handles full import with intelligent deduplication
- `TranscriptionService` - OpenAI Whisper integration for audio
- `SentimentAnalyzer` - Analyzes message sentiment using Sentimental gem
- `AnalyticsEngine` - Computes metrics, trends, and insights

### Key Design Patterns

**Deduplication Strategy**: Messages are hashed using `SHA256(timestamp|participant|content)` and stored with unique constraint on `[conversation_id, content_hash]`.

**Import Intelligence**: Each import batch tracks what's new since the previous import, allowing for:
- Diff-style views of latest additions
- Longitudinal analysis across imports
- Safe re-import of full exports

**Analytics Caching**: Daily metrics are pre-computed and cached in `DailyMetric` model for fast dashboard loading.

## Setup Instructions

### Prerequisites

- Ruby 3.4.7
- Node.js (for asset compilation)
- OpenAI API key (for audio transcription, optional)

**Note:** Uses SQLite for local development (no PostgreSQL needed). PostgreSQL is only required for production deployment.

### Installation

1. **Clone and enter the directory**:
   ```bash
   cd vlad.gem
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Create and setup database**:
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Set environment variables** (optional, for audio transcription):
   ```bash
   export OPENAI_API_KEY="your-openai-api-key"
   ```

5. **Start the development server**:
   ```bash
   bin/dev
   # This starts both Rails server and Tailwind CSS watcher
   ```

   Or separately:
   ```bash
   bin/rails server
   # In another terminal:
   bin/rails tailwindcss:watch
   ```

6. **Visit the app**:
   ```
   http://localhost:3000
   ```

### Running Background Jobs

For audio transcription and import processing:

```bash
bundle exec sidekiq
```

## Usage Guide

### Exporting from WhatsApp

1. Open the chat in WhatsApp
2. Tap the three dots (⋮) menu
3. Select "More" → "Export chat"
4. Choose "Without media" (recommended for faster processing)
5. Save the `.txt` file

### Importing into Vlad's Gem

1. Create a new Conversation
2. Click "Import Chat"
3. Upload the exported `.txt` file
4. Wait for processing (runs in background)
5. Explore the analytics!

### Re-importing

You can safely re-import the same conversation multiple times:

- The app detects duplicate messages automatically
- Only new messages are added
- "New Since Last Import" view shows what changed
- Previous imports are preserved for historical comparison

### Audio Transcription

1. Navigate to a message that represents an audio file
2. Click "Add Audio Transcript"
3. Upload the audio file (`.mp3`, `.m4a`, `.wav`, etc.)
4. Transcription happens in background via OpenAI Whisper
5. Transcribed text is added to analytics and search

## Database Schema

### Core Tables

```sql
conversations
- title, description
- first_message_at, last_message_at
- total_messages_count

participants
- conversation_id, name, phone_number
- messages_count

import_batches
- conversation_id, filename, status
- file_checksum (MD5 for duplicate detection)
- messages_imported, messages_skipped, new_messages_count

messages
- conversation_id, participant_id, import_batch_id
- sent_at, content, message_type, media_type
- content_hash (SHA256 for deduplication - UNIQUE)
- sentiment_score, sentiment_label
- character_count, word_count, emoji_count
- response_time_seconds

audio_transcripts
- message_id, transcript_text, status
- confidence_score, language_detected, duration_seconds

daily_metrics (pre-computed analytics)
- conversation_id, metric_date
- total_messages, messages_by_participant
- avg_response_time, avg_sentiment, sentiment_distribution
- conversation_initiations, top_emojis, messages_by_hour

conversation_chapters
- conversation_id, start_date, end_date
- title, description, avg_sentiment, dominant_theme
```

## Example Queries

### Find messages with high sentiment shift

```ruby
Message.where("sentiment_score > 0.5 OR sentiment_score < -0.5")
  .order(sent_at: :desc)
```

### Compare two time periods

```ruby
engine = AnalyticsEngine.new(conversation)
comparison = engine.compare_periods(
  Date.parse("2026-01-01"), Date.parse("2026-01-31"),
  Date.parse("2026-02-01"), Date.parse("2026-02-28")
)
```

### Get top emoji usage

```ruby
engine = AnalyticsEngine.new(conversation)
engine.top_emojis(limit: 20)
```

## Development Roadmap

### Phase 1: Core Features (Completed)
- ✅ WhatsApp export parsing
- ✅ Import with deduplication
- ✅ Basic analytics and visualizations
- ✅ Sentiment analysis
- ✅ Audio transcription architecture

### Phase 2: Enhanced Analytics (Future)
- Topic modeling and keyword extraction
- Named entity recognition
- More sophisticated conversation chapter detection
- Export analytics to PDF/CSV
- Comparison views between multiple conversations

### Phase 3: Intelligence Features (Future)
- Conversation health scoring
- Engagement prediction
- Relationship milestone detection
- Custom analytics queries via UI

## Project Philosophy

This is a **hobby project** optimized for:

- **Clarity over cleverness**: Simple, explicit Rails patterns
- **Maintainability**: Clean separation of concerns (parsers, importers, analytics)
- **Historical insight**: Not real-time sync, but rich longitudinal analysis
- **Personal use**: Not designed for multi-tenancy or production deployment

## Contributing

This is a personal project, but feel free to fork and adapt for your own use!

## License

Personal project - use at your own discretion.

## Acknowledgments

Built with love for understanding the conversations that matter.

---

**Vlad's Gem 💎** - Because every conversation tells a story.
