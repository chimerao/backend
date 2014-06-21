class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.integer     :user_id,           null: false
      t.string      :name,              null: false, limit: 40 #, unique: true
      t.string      :site_identifier,   null: false, limit: 40, unique: true
      t.boolean     :is_creator,        default: false
      t.string      :bio,               limit: 160
      t.string      :homepage,          limit: 80
      t.string      :location,          limit: 80
      t.text        :description
      t.string      :exposed_profiles
      t.string      :preferences
      t.integer     :restricted_status, default: 0
      t.datetime    :last_logged_in_at
      t.timestamps
    end

    add_attachment :profiles, :banner_image

    add_index :profiles, :user_id
    add_index :profiles, :name
    add_index :profiles, :site_identifier, unique: true
  end
end