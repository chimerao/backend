class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string    :email,                         limit: 80, null: false
      t.string    :crypted_password,              null: false
      t.string    :salt,                          null: false
      t.string    :remember_me_token,             default: nil
      t.datetime  :remember_me_token_expires_at,  deafult: nil
      t.integer   :default_profile_id
      t.integer   :restricted_status,             default: 0
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :remember_me_token
  end
end