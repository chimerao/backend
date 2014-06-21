class CreateSubmissionFolders < ActiveRecord::Migration
  def change
    create_table :submission_folders do |t|
      t.integer     :profile_id,          null: false
      t.string      :name,                limit: 80, null: false
      t.string      :url_name,            limit: 80
      t.boolean     :is_permanent,        default: false
      t.timestamps
    end

    add_index :submission_folders, :profile_id

    create_table :filters_submission_folders do |t|
      t.integer   :filter_id
      t.integer   :submission_folder_id
    end
    add_index :filters_submission_folders,
              [:filter_id, :submission_folder_id],
              name: 'index_fsf_on_filter_id_and_submission_folder_id'
    add_index :filters_submission_folders,
              [:submission_folder_id, :filter_id],
              name: 'index_fsf_on_submission_folder_id_and_filter_id'

    create_table :submission_folders_submissions do |t|
      t.integer   :submission_folder_id
      t.integer   :submission_id
    end
    add_index :submission_folders_submissions,
              [:submission_folder_id, :submission_id],
              name: 'index_sfs_on_submission_folder_id_and_submission_id'
    add_index :submission_folders_submissions,
              [:submission_id, :submission_folder_id],
              name: 'index_sfs_on_submission_id_and_submission_folder_id'

  end
end
