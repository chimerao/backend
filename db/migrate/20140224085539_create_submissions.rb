class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.integer     :profile_id,            null: false
      t.string      :title,                 length: 80
      t.string      :url_title,             length: 80
      t.text        :description
      t.integer     :submission_id
      t.integer     :submission_group_id
      t.integer     :replyable_id
      t.string      :replyable_type
      t.integer     :rating,                default: 0
      t.integer     :views,                 default: 0
      t.integer     :width
      t.integer     :height
      t.string      :type
      t.integer     :owner_id
      t.datetime    :published_at
      t.timestamps
    end

    add_attachment :submissions, :file

    add_index :submissions, :profile_id
    add_index :submissions, :submission_id
    add_index :submissions, :submission_group_id
    add_index :submissions, :url_title
    add_index :submissions, :rating
    add_index :submissions, :type
  end
end
