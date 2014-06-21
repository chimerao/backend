json.array!(@filters) do |filter|
  json.extract! filter, :id, :name, :url_name, :description, :opt_in, :created_at
  json.type filter.class.name
  json.url profile_filter_url(@profile, filter)
  if filter.profile == current_profile
    json.members_url profile_filter_members_url(@profile, filter)
  end
end
