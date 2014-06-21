json.id @profile.id
json.type @profile.class.name
json.name @profile.name
json.site_identifier @profile.site_identifier
json.bio @profile.bio
json.location @profile.location
json.homepage @profile.homepage
json.following_count @following_count
json.followers_count @followers_count
json.following current_profile ? current_profile.following_profile?(@profile) : false
json.created_at @profile.created_at
json.banner_image do
  json.url paperclip_url(@profile.banner_image.url)
  json.preview_url paperclip_url(@profile.banner_image(:preview))
end
json.profile_pic do
  json.partial! 'profile_pics/profile_pic', profile: @profile, profile_pic: @profile.default_profile_pic
end
json.other_profiles @other_profiles do |profile|
  json.id profile.id
  json.type profile.class.name
  json.name profile.name
  json.site_identifier profile.site_identifier
  json.url profile_home_url(profile.site_identifier)
  json.profile_pic do
    json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
  end
end
json.filters @public_filters do |filter|
  json.extract! filter, :id, :name, :url_name, :description, :opt_in, :created_at
  json.type filter.class.name
  json.url profile_filter_url(@profile, filter)  
  json.join_url join_profile_filter_url(@profile, filter)
end
# json.tags @relation_tags
json.url profile_home_url(@profile.site_identifier)
json.submissions_url profile_submissions_url(@profile)
json.journals_url profile_journals_url(@profile)
json.filters_url profile_filters_url(@profile)
json.submission_folders_url profile_submission_folders_url(@profile)
# json.favorite_folders_url profile_favorite_folders_url(@profile)
json.streams_url profile_streams_url(@profile)
json.follow_url follow_profile_url(@profile)
if @profile == current_profile
  json.profile_pics_url profile_pics_url(@profile)
  json.messages_url profile_messages_url(@profile)
  json.notifications_url profile_notifications_url(@profile)
  json.upload_url unpublished_profile_submissions_url(@profile)
  json.new_messages_count @profile.received_messages.unread.count
  json.notifications_count @profile.notifications.count
end
