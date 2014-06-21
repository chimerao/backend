json.array!(@folders) do |folder|
  json.extract! folder, :id, :name, :url_name, :created_at
  json.type folder.class.name
  json.filters folder.filters do |filter|
    json.extract! filter, :id, :name
  end
  json.url profile_submission_folder_url(@profile, folder)
end