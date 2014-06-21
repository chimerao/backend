json.array!(@tidbits) do |tidbit|
  json.action tidbit.action
  json.created_at tidbit.created_at
  
  case tidbit.action
  when 'Watch'
    profile = tidbit.targetable
    target = tidbit.profile
  when 'Favorite'
    profile = tidbit.targetable.profile
    target = tidbit.targetable.favable
  when 'Share'
    profile = tidbit.targetable.profile
    target = tidbit.targetable.shareable
  else
    profile = tidbit.targetable.profile
    target = tidbit.targetable
  end

  json.profile do
    json.id profile.id
    json.type profile.class.name
    json.name profile.name
    json.site_identifier profile.site_identifier
    json.url profile_url(profile)
    json.profile_pic do
      if tidbit.action == 'Comment'
        json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: target.profile_pic || profile.default_profile_pic
      else
        json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
      end
    end
  end

  json.target do
    case tidbit.action
    when 'Watch'
      json.id target.id
      json.type target.class.name
      json.name target.name
      json.site_identifier target.site_identifier
      json.url profile_url(target)
      json.profile_pic do
        json.partial! 'profile_pics/profile_pic', profile: target, profile_pic: target.default_profile_pic
      end
    when 'Comment'
      json.id         target.id
      json.type       target.class.name
      json.body       target.body
      json.commentable do
        json.id         target.commentable.id
        json.type       target.commentable.class.name
        json.title      target.commentable.title
        json.url_title  target.commentable.url_title
        json.url        polymorphic_url(target.commentable)
        if not target.commentable.is_a?(Journal)
          json.image do
            json.thumb_64  { json.url paperclip_url(target.commentable.image(:thumb_64)) }
            json.thumb_96  { json.url paperclip_url(target.commentable.image(:thumb_96)) }
            json.thumb_120 { json.url paperclip_url(target.commentable.image(:thumb_120)) }
            json.thumb_240 { json.url paperclip_url(target.commentable.image(:thumb_240)) }
            json.thumb_400 { json.url paperclip_url(target.commentable.image(:thumb_400)) }
            json.thumb_512 { json.url paperclip_url(target.commentable.image(:thumb_512)) }
          end
        end
      end
    else
      json.id         target.id
      json.type       target.class.name
      json.title      target.title
      json.url_title  target.url_title
      json.url        polymorphic_url(target)
      if not target.is_a?(Journal)
        json.image do
          json.thumb_64  { json.url paperclip_url(target.image(:thumb_64)) }
          json.thumb_96  { json.url paperclip_url(target.image(:thumb_96)) }
          json.thumb_120 { json.url paperclip_url(target.image(:thumb_120)) }
          json.thumb_240 { json.url paperclip_url(target.image(:thumb_240)) }
          json.thumb_400 { json.url paperclip_url(target.image(:thumb_400)) }
          json.thumb_512 { json.url paperclip_url(target.image(:thumb_512)) }
        end
      end
    end
  end
end
