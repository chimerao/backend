json.array!(@journals) do |journal|
  json.extract! journal, :id, :title, :url_title, :body, :favorites_count, :comments_count, :shares_count, :views_count, :published_at, :updated_at
  json.type journal.class.name
  json.url journal_url(journal)
  json.profile do
    json.id journal.profile.id
    json.type journal.profile.class.name
    json.name journal.profile.name
    json.site_identifier journal.profile.site_identifier
    json.url profile_home_url(journal.profile.site_identifier)
  end
  json.profile_pic do
    json.partial! 'profile_pics/profile_pic', profile: journal.profile, profile_pic: journal.actual_profile_pic
  end
end
