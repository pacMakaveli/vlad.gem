class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :first_message_at
      t.datetime :last_message_at
      t.integer :total_messages_count, default: 0
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :conversations, :first_message_at
    add_index :conversations, :last_message_at
  end
end
