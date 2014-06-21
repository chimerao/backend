class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer   :profile_id,      :null => false
      t.integer   :votable_id,      :null => false
      t.string    :votable_type,    :limit => 60, :null => false
      t.datetime  :created_at
    end

    add_index :votes, :profile_id
    add_index :votes, :votable_id
    add_index :votes, :votable_type
  end
end
