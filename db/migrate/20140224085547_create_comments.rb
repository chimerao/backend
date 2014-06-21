class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer     :profile_id,          null: false
      t.integer     :profile_pic_id
      t.integer     :comment_id
      t.integer     :commentable_id
      t.string      :commentable_type,    limit: 60
      t.text        :body
      t.timestamps
    end

    add_attachment :comments, :image

    add_index :comments, :profile_id
    add_index :comments, :commentable_id
    add_index :comments, :commentable_type
    add_index :comments, :comment_id
  end
end
