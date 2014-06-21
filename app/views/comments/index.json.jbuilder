json.array!(@comments) do |comment|
  json.extract! comment, :id, :comment_id, :created_at, :updated_at
  json.body comment.enhanced_body
  json.is_pose comment.pose?
  json.votes_count comment.votes.count
  json.image_url comment.has_image? ? paperclip_url(comment.image(:large)) : nil
  json.profile do
    json.id comment.profile_id
    json.name comment.profile.name
    json.site_identifier comment.profile.site_identifier
    json.url profile_home_url(comment.profile.site_identifier)
  end
  json.profile_pic do
    json.id comment.profile_pic_id
    json.type comment.profile_pic.class.name
    json.url paperclip_url(url_for_profile_pic(comment.profile, size: :pixels_96, profile_pic: comment.profile_pic))
  end
  json.commentable do
  	json.id comment.commentable_id
  	json.type comment.commentable_type
  end
  json.url polymorphic_url([comment.commentable, comment])
end
