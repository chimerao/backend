class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer   :profile_id,      null: false
      t.integer   :shareable_id,    null: false
      t.string    :shareable_type,  null: false, limit: 60
      t.datetime  :created_at
    end

    add_index :shares, :profile_id
    add_index :shares, :shareable_id
    add_index :shares, :shareable_type
  end
end
