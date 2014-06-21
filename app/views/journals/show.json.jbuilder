json.extract! @journal, :id, :title, :url_title, :body, :favorites_count, :comments_count, :shares_count, :views_count, :published_at, :updated_at
json.type @journal.class.name
json.tags @journal.tag_list
json.profile do
  json.id @journal.profile.id
  json.type @journal.profile.class.name
  json.name @journal.profile.name
  json.site_identifier @journal.profile.site_identifier
  json.url profile_home_url(@journal.profile.site_identifier)
end
json.profile_pic do
  json.partial! 'profile_pics/profile_pic', profile: @journal.profile, profile_pic: @journal.actual_profile_pic
end
json.in_series @journal.in_series?
if @journal.in_series?
  json.series do
    if @journal.previous_journal
      json.extract! @journal.previous_journal, :id, :title, :url_title, :published_at
      json.type @journal.previous_journal.class.name
      json.url journal_url(@journal.previous_journal)
    end
    if @journal.next_journal
      json.extract! @journal.next_journal, :id, :title, :url_title, :published_at
      json.type @journal.next_journal.class.name
      json.url journal_url(@journal.next_journal)
    end
  end
end
if @journal.replyable
  json.replyable do
    json.extract! @journal.replyable, :id, :title, :url_title, :published_at
    json.type @journal.replyable.class.name
    json.url polymorphic_url(@journal.replyable)
  end
else
  json.replyable nil
end
json.replies_count @journal.replies.count
if @journal.replies.count > 0
  json.replies @journal.replies.each do |reply|
    json.extract! reply, :id, :title, :url_title, :published_at
    json.type reply.class.name
    json.url polymorphic_url(reply)
  end
end
json.is_faved current_profile ? current_profile.has_faved?(@journal) : false
json.is_shared current_profile ? current_profile.has_shared?(@journal) : false
json.url journal_url(@journal)
json.comments_url journal_comments_url(@journal)
json.fave_url fave_journal_url(@journal)
json.share_url share_journal_url(@journal)
