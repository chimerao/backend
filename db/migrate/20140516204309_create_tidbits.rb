class CreateTidbits < ActiveRecord::Migration
  def change
    create_table :tidbits do |t|
      t.integer     :profile_id,      null: false
      t.integer     :targetable_id,   null: false
      t.string      :targetable_type, null: false, limit: 60
      t.datetime    :created_at
    end

    add_index :tidbits, :profile_id
    add_index :tidbits, :targetable_id
    add_index :tidbits, :targetable_type
  end
end