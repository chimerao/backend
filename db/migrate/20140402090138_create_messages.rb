class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer       :sender_id,         null: false
      t.integer       :recipient_id,      null: false
      t.integer       :profile_pic_id
      t.string        :subject,           limit: 120
      t.text          :body,              null: false
      t.boolean       :unread,            default: true
      t.boolean       :deleted,           default: false
      t.boolean       :archived,          default: false
      t.boolean       :sent,              default: false
      t.timestamps
    end

    add_index :messages, :sender_id
    add_index :messages, :recipient_id
  end
end
