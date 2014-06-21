class CreateFilterProfiles < ActiveRecord::Migration
  def change
    create_table :filter_profiles do |t|
      t.integer     :profile_id,      null: false
      t.integer     :filter_id,       null: false
      t.boolean     :is_approved,     default: false
      t.timestamps
    end

    add_index :filter_profiles, :profile_id
    add_index :filter_profiles, :filter_id
  end
end
