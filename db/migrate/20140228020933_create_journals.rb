class CreateJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.integer     :profile_id,      :null => false
      t.integer     :profile_pic_id
      t.string      :title,           :limit => 80
      t.string      :url_title,       :limit => 80
      t.text        :body
      t.integer     :journal_id
      t.integer     :replyable_id
      t.string      :replyable_type
      t.integer     :views,           :default => 0
      t.datetime    :published_at
      t.timestamps
    end

    add_index :journals, :profile_id
    add_index :journals, :journal_id
    add_index :journals, :url_title
  end
end
