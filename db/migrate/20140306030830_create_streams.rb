class CreateStreams < ActiveRecord::Migration
  def change
    create_table :streams do |t|
      t.integer     :profile_id,      :null => false
      t.string      :name,            :null => false
      t.boolean     :is_public,       :default => false
      t.boolean     :is_permanent,    :default => false
      t.string      :rules,           :null => false
      t.timestamps
    end

    add_index :streams, :profile_id
  end
end
