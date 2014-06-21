class CreateProfilePics < ActiveRecord::Migration
  def change
    create_table :profile_pics do |t|
      t.integer     :profile_id,        :null => false
      t.string      :title,             :length => 40
      t.boolean     :is_default,        :default => false
    end

    add_attachment :profile_pics, :image

    add_index :profile_pics, :profile_id
  end
end
