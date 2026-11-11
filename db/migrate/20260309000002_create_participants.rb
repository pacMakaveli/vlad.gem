class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone_number
      t.string :participant_type, default: "user" # user, contact
      t.integer :messages_count, default: 0
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :participants, [:conversation_id, :name], unique: true
  end
end
