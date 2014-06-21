class CreateJournalImages < ActiveRecord::Migration
  def change
    create_table :journal_images do |t|
      t.integer     :profile_id,      null: false
      t.integer     :journal_id #,      null: false
      t.datetime    :created_at
    end

    add_attachment :journal_images, :image

    add_index :journal_images, :journal_id
  end
end
