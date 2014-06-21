# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140516204309) do

  create_table "collaborations", force: true do |t|
    t.integer  "profile_id",                      null: false
    t.integer  "submission_id",                   null: false
    t.boolean  "is_approved",     default: false
    t.boolean  "show_on_profile", default: true
    t.integer  "profile_pic_id"
    t.datetime "acted_on"
  end

  add_index "collaborations", ["profile_id"], name: "index_collaborations_on_profile_id"
  add_index "collaborations", ["submission_id"], name: "index_collaborations_on_submission_id"

  create_table "comments", force: true do |t|
    t.integer  "profile_id",                    null: false
    t.integer  "profile_pic_id"
    t.integer  "comment_id"
    t.integer  "commentable_id"
    t.string   "commentable_type",   limit: 60
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "comments", ["comment_id"], name: "index_comments_on_comment_id"
  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], name: "index_comments_on_commentable_type"
  add_index "comments", ["profile_id"], name: "index_comments_on_profile_id"

  create_table "favorite_folders", force: true do |t|
    t.integer  "profile_id",                              null: false
    t.string   "name",         limit: 80
    t.string   "url_name",     limit: 80
    t.boolean  "is_private",              default: false
    t.boolean  "is_permanent",            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favorite_folders", ["profile_id"], name: "index_favorite_folders_on_profile_id"

  create_table "favorites", force: true do |t|
    t.integer  "profile_id",                    null: false
    t.integer  "favable_id",                    null: false
    t.string   "favable_type",       limit: 60, null: false
    t.integer  "favorite_folder_id",            null: false
    t.datetime "created_at"
  end

  add_index "favorites", ["favable_id"], name: "index_favorites_on_favable_id"
  add_index "favorites", ["favable_type"], name: "index_favorites_on_favable_type"
  add_index "favorites", ["favorite_folder_id"], name: "index_favorites_on_favorite_folder_id"
  add_index "favorites", ["profile_id"], name: "index_favorites_on_profile_id"

  create_table "filter_profiles", force: true do |t|
    t.integer  "profile_id",                  null: false
    t.integer  "filter_id",                   null: false
    t.boolean  "is_approved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "filter_profiles", ["filter_id"], name: "index_filter_profiles_on_filter_id"
  add_index "filter_profiles", ["profile_id"], name: "index_filter_profiles_on_profile_id"

  create_table "filters", force: true do |t|
    t.integer  "profile_id",                             null: false
    t.boolean  "opt_in",                 default: false
    t.string   "name",        limit: 30
    t.string   "url_name",    limit: 30
    t.string   "description"
    t.datetime "created_at"
  end

  add_index "filters", ["profile_id"], name: "index_filters_on_profile_id"
  add_index "filters", ["url_name"], name: "index_filters_on_url_name"

  create_table "filters_journals", force: true do |t|
    t.integer "filter_id"
    t.integer "journal_id"
  end

  add_index "filters_journals", ["filter_id", "journal_id"], name: "index_filters_journals_on_filter_id_and_journal_id"
  add_index "filters_journals", ["journal_id", "filter_id"], name: "index_filters_journals_on_journal_id_and_filter_id"

  create_table "filters_submission_folders", force: true do |t|
    t.integer "filter_id"
    t.integer "submission_folder_id"
  end

  add_index "filters_submission_folders", ["filter_id", "submission_folder_id"], name: "index_fsf_on_filter_id_and_submission_folder_id"
  add_index "filters_submission_folders", ["submission_folder_id", "filter_id"], name: "index_fsf_on_submission_folder_id_and_filter_id"

  create_table "filters_submissions", force: true do |t|
    t.integer "filter_id"
    t.integer "submission_id"
  end

  add_index "filters_submissions", ["filter_id", "submission_id"], name: "index_filters_submissions_on_filter_id_and_submission_id"
  add_index "filters_submissions", ["submission_id", "filter_id"], name: "index_filters_submissions_on_submission_id_and_filter_id"

  create_table "journal_images", force: true do |t|
    t.integer  "profile_id",         null: false
    t.integer  "journal_id"
    t.datetime "created_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "journal_images", ["journal_id"], name: "index_journal_images_on_journal_id"

  create_table "journals", force: true do |t|
    t.integer  "profile_id",                            null: false
    t.integer  "profile_pic_id"
    t.string   "title",          limit: 80
    t.string   "url_title",      limit: 80
    t.text     "body"
    t.integer  "journal_id"
    t.integer  "replyable_id"
    t.string   "replyable_type"
    t.integer  "views",                     default: 0
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journals", ["journal_id"], name: "index_journals_on_journal_id"
  add_index "journals", ["profile_id"], name: "index_journals_on_profile_id"
  add_index "journals", ["url_title"], name: "index_journals_on_url_title"

  create_table "messages", force: true do |t|
    t.integer  "sender_id",                                  null: false
    t.integer  "recipient_id",                               null: false
    t.integer  "profile_pic_id"
    t.string   "subject",        limit: 120
    t.text     "body",                                       null: false
    t.boolean  "unread",                     default: true
    t.boolean  "deleted",                    default: false
    t.boolean  "archived",                   default: false
    t.boolean  "sent",                       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["recipient_id"], name: "index_messages_on_recipient_id"
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id"

  create_table "notifications", force: true do |t|
    t.integer  "profile_id",      null: false
    t.integer  "notifyable_id",   null: false
    t.string   "notifyable_type", null: false
    t.string   "rules"
    t.datetime "created_at"
  end

  add_index "notifications", ["notifyable_id"], name: "index_notifications_on_notifyable_id"
  add_index "notifications", ["notifyable_type"], name: "index_notifications_on_notifyable_type"
  add_index "notifications", ["profile_id"], name: "index_notifications_on_profile_id"

  create_table "profile_pics", force: true do |t|
    t.integer  "profile_id",                         null: false
    t.string   "title"
    t.boolean  "is_default",         default: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "profile_pics", ["profile_id"], name: "index_profile_pics_on_profile_id"

  create_table "profiles", force: true do |t|
    t.integer  "user_id",                                               null: false
    t.string   "name",                      limit: 40,                  null: false
    t.string   "site_identifier",           limit: 40,                  null: false
    t.boolean  "is_creator",                            default: false
    t.string   "bio",                       limit: 160
    t.string   "homepage",                  limit: 80
    t.string   "location",                  limit: 80
    t.text     "description"
    t.string   "exposed_profiles"
    t.string   "preferences"
    t.integer  "restricted_status",                     default: 0
    t.datetime "last_logged_in_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "banner_image_file_name"
    t.string   "banner_image_content_type"
    t.integer  "banner_image_file_size"
    t.datetime "banner_image_updated_at"
  end

  add_index "profiles", ["name"], name: "index_profiles_on_name"
  add_index "profiles", ["site_identifier"], name: "index_profiles_on_site_identifier", unique: true
  add_index "profiles", ["user_id"], name: "index_profiles_on_user_id"

  create_table "shares", force: true do |t|
    t.integer  "profile_id",                null: false
    t.integer  "shareable_id",              null: false
    t.string   "shareable_type", limit: 60, null: false
    t.datetime "created_at"
  end

  add_index "shares", ["profile_id"], name: "index_shares_on_profile_id"
  add_index "shares", ["shareable_id"], name: "index_shares_on_shareable_id"
  add_index "shares", ["shareable_type"], name: "index_shares_on_shareable_type"

  create_table "streams", force: true do |t|
    t.integer  "profile_id",                   null: false
    t.string   "name",                         null: false
    t.boolean  "is_public",    default: false
    t.boolean  "is_permanent", default: false
    t.string   "rules",                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "streams", ["profile_id"], name: "index_streams_on_profile_id"

  create_table "submission_folders", force: true do |t|
    t.integer  "profile_id",                              null: false
    t.string   "name",         limit: 80,                 null: false
    t.string   "url_name",     limit: 80
    t.boolean  "is_permanent",            default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "submission_folders", ["profile_id"], name: "index_submission_folders_on_profile_id"

  create_table "submission_folders_submissions", force: true do |t|
    t.integer "submission_folder_id"
    t.integer "submission_id"
  end

  add_index "submission_folders_submissions", ["submission_folder_id", "submission_id"], name: "index_sfs_on_submission_folder_id_and_submission_id"
  add_index "submission_folders_submissions", ["submission_id", "submission_folder_id"], name: "index_sfs_on_submission_id_and_submission_folder_id"

  create_table "submissions", force: true do |t|
    t.integer  "profile_id",                      null: false
    t.string   "title"
    t.string   "url_title"
    t.text     "description"
    t.integer  "submission_id"
    t.integer  "submission_group_id"
    t.integer  "replyable_id"
    t.string   "replyable_type"
    t.integer  "rating",              default: 0
    t.integer  "views",               default: 0
    t.integer  "width"
    t.integer  "height"
    t.string   "type"
    t.integer  "owner_id"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "submissions", ["profile_id"], name: "index_submissions_on_profile_id"
  add_index "submissions", ["rating"], name: "index_submissions_on_rating"
  add_index "submissions", ["submission_group_id"], name: "index_submissions_on_submission_group_id"
  add_index "submissions", ["submission_id"], name: "index_submissions_on_submission_id"
  add_index "submissions", ["type"], name: "index_submissions_on_type"
  add_index "submissions", ["url_title"], name: "index_submissions_on_url_title"

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true

  create_table "tidbits", force: true do |t|
    t.integer  "profile_id",                 null: false
    t.integer  "targetable_id",              null: false
    t.string   "targetable_type", limit: 60, null: false
    t.datetime "created_at"
  end

  add_index "tidbits", ["profile_id"], name: "index_tidbits_on_profile_id"
  add_index "tidbits", ["targetable_id"], name: "index_tidbits_on_targetable_id"
  add_index "tidbits", ["targetable_type"], name: "index_tidbits_on_targetable_type"

  create_table "users", force: true do |t|
    t.string   "username",                     limit: 40,             null: false
    t.string   "email",                        limit: 80,             null: false
    t.string   "crypted_password",                                    null: false
    t.string   "salt",                                                null: false
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.integer  "default_profile_id"
    t.integer  "restricted_status",                       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token"
  add_index "users", ["username"], name: "index_users_on_username", unique: true

  create_table "votes", force: true do |t|
    t.integer  "profile_id",              null: false
    t.integer  "votable_id",              null: false
    t.string   "votable_type", limit: 60, null: false
    t.datetime "created_at"
  end

  add_index "votes", ["profile_id"], name: "index_votes_on_profile_id"
  add_index "votes", ["votable_id"], name: "index_votes_on_votable_id"
  add_index "votes", ["votable_type"], name: "index_votes_on_votable_type"

end
