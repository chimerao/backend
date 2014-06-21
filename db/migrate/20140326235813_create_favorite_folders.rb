class CreateFavoriteFolders < ActiveRecord::Migration
  def change
    create_table :favorite_folders do |t|
      t.integer     :profile_id,          null: false
      t.string      :name,                limit: 80
      t.string      :url_name,            limit: 80
      t.boolean     :is_private,          default: false
      t.boolean     :is_permanent,        default: false
      t.timestamps
    end

    add_index :favorite_folders, :profile_id

  end
end
