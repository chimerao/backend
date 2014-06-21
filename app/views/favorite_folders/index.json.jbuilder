json.array!(@folders) do |folder|
  json.extract! folder, :id, :name, :url_name, :is_private, :created_at
  json.type folder.class.name
  json.url profile_favorite_folder_url(@profile, folder)
end