json.array!(@notifications) do |notification|
  json.extract! notification, :id, :created_at #, :rules
  if notification.notifyable_type == 'Collaboration'
    json.type 'Collaboration'
    json.actor do
      profile = notification.notifyable.submission.profile
      json.id profile.id
      json.type profile.class.name
      json.name profile.name
      json.site_identifier profile.site_identifier
      json.url profile_home_url(profile.site_identifier)
      json.profile_pic do
        json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
      end
    end
    json.target do
      submission = notification.notifyable.submission
      json.id submission.id
      json.type submission.class.name
      json.title submission.title
      json.url submission_url(submission)
      json.image do
        json.thumb_64  { json.url paperclip_url(submission.image(:thumb_64)) }
        json.thumb_96  { json.url paperclip_url(submission.image(:thumb_96)) }
        json.thumb_180 { json.url paperclip_url(submission.image(:thumb_180)) }
        json.thumb_240 { json.url paperclip_url(submission.image(:thumb_240)) }
        json.thumb_400 { json.url paperclip_url(submission.image(:thumb_400)) }
        json.resized   { json.url paperclip_url(submission.image(:resized)) }
      end
    end
    json.action do
      json.url review_approve_submission_url(notification.notifyable.submission)
    end
  elsif notification.notifyable_type == 'FilterProfile'
    json.type 'FilterJoin'
    json.actor do
      profile = notification.notifyable.profile
      json.id profile.id
      json.type profile.class.name
      json.name profile.name
      json.site_identifier profile.site_identifier
      json.url profile_home_url(profile.site_identifier)
      json.profile_pic do
        json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
      end
    end
    json.target do
      filter = notification.notifyable.filter
      json.id filter.id
      json.type filter.class.name
      json.name filter.name
      json.url profile_filter_url(notification.notifyable.filter.profile, notification.notifyable.filter)
    end
    json.action do
      json.url review_join_profile_filter_member_url(current_profile, notification.notifyable.filter, notification.notifyable.profile)
    end
  elsif notification.notifyable_type == 'Submission'
    json.type 'SubmissionClaim'
    json.actor do
      profile = notification.notifyable.owner
      json.id profile.id
      json.type profile.class.name
      json.name profile.name
      json.site_identifier profile.site_identifier
      json.url profile_home_url(profile.site_identifier)
      json.profile_pic do
        json.partial! 'profile_pics/profile_pic', profile: profile, profile_pic: profile.default_profile_pic
      end
    end
    json.target do
      submission = notification.notifyable
      json.id submission.id
      json.type submission.class.name
      json.title submission.title
      json.url submission_url(submission)
      json.image do
        json.thumb_64  { json.url paperclip_url(submission.image(:thumb_64)) }
        json.thumb_96  { json.url paperclip_url(submission.image(:thumb_96)) }
        json.thumb_180 { json.url paperclip_url(submission.image(:thumb_180)) }
        json.thumb_240 { json.url paperclip_url(submission.image(:thumb_240)) }
        json.thumb_400 { json.url paperclip_url(submission.image(:thumb_400)) }
        json.resized   { json.url paperclip_url(submission.image(:resized)) }
      end
    end
    json.action do
      json.url review_relinquish_submission_url(notification.notifyable)
    end
  end
end
