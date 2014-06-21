class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer   :profile_id,        null: false
      t.integer   :notifyable_id,     null: false
      t.string    :notifyable_type,   null: false
      t.string    :rules,             length: 120
      t.datetime  :created_at
    end

    add_index :notifications, :profile_id
    add_index :notifications, :notifyable_id
    add_index :notifications, :notifyable_type
  end
end
