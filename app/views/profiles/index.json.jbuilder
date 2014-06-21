json.array!(@profiles) do |profile|
  json.extract! profile, :id, :name, :site_identifier
  json.url profile_home_url(profile.site_identifier)
  json.profile_pic do
    json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
  end
  json.active profile == current_profile
end
