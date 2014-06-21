class CreateCollaborations < ActiveRecord::Migration
  def change
    create_table :collaborations do |t|
      t.integer   :profile_id,          :null => false
      t.integer   :submission_id,       :null => false
      t.boolean   :is_approved,         :default => false
      t.boolean   :show_on_profile,     :default => true
      t.integer   :profile_pic_id
      t.datetime  :acted_on
    end

    add_index :collaborations, :profile_id
    add_index :collaborations, :submission_id
  end
end
