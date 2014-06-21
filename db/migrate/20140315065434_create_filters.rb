class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.integer   :profile_id,      :null => false
      t.boolean   :opt_in,          :default => false
      t.string    :name,            :limit => 30
      t.string    :url_name,        :limit => 30
      t.string    :description,     :limit => 255
      t.datetime  :created_at
    end

    add_index :filters, :profile_id
    add_index :filters, :url_name

    create_table :filters_submissions do |t|
      t.integer   :filter_id
      t.integer   :submission_id
    end

    create_table :filters_journals do |t|
      t.integer   :filter_id
      t.integer   :journal_id
    end

    add_index :filters_submissions, [:filter_id, :submission_id]
    add_index :filters_submissions, [:submission_id, :filter_id]
    add_index :filters_journals, [:filter_id, :journal_id]
    add_index :filters_journals, [:journal_id, :filter_id]
  end
end
