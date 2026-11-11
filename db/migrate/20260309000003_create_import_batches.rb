class CreateImportBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :import_batches do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :filename
      t.string :status, default: "pending" # pending, processing, completed, failed
      t.integer :total_lines, default: 0
      t.integer :messages_imported, default: 0
      t.integer :messages_skipped, default: 0
      t.integer :new_messages_count, default: 0 # New messages since last import
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.string :file_checksum # MD5 hash to detect duplicate imports
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :import_batches, :status
    add_index :import_batches, :created_at
    add_index :import_batches, :file_checksum
  end
end
