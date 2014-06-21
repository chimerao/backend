class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.integer   :profile_id,          null: false
      t.integer   :favable_id,          null: false
      t.string    :favable_type,        null: false, limit: 60
      t.integer   :favorite_folder_id,  null: false
      t.datetime  :created_at
    end

    add_index :favorites, :profile_id
    add_index :favorites, :favable_id
    add_index :favorites, :favable_type
    add_index :favorites, :favorite_folder_id
  end
end
