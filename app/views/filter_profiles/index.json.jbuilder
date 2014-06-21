json.array!(@members) do |filter_profile|
  json.extract! filter_profile.profile, :id, :name, :site_identifier
  json.type filter_profile.profile.class.name
  json.url profile_home_url(filter_profile.profile.site_identifier)
  json.profile_pic do
    json.partial! 'profile_pics/profile_pic', profile_pic: filter_profile.profile.default_profile_pic
  end
  json.is_approved filter_profile.is_approved
end
