json.extract! @submission, :id, :title, :url_title, :description, :profile_id, :width, :height, :favorites_count, :comments_count, :shares_count, :views_count, :published_at, :updated_at
json.type @submission.class.name
json.tags @submission.tag_list
json.is_adult @submission.is_adult?
json.file paperclip_url(@submission.file.url)
json.image do
  json.thumb_96  { json.url paperclip_url(@submission.image(:thumb_96)) }
  json.thumb_240 { json.url paperclip_url(@submission.image(:thumb_240)) }
  json.thumb_400 { json.url paperclip_url(@submission.image(:thumb_400)) }
  json.resized   { json.url paperclip_url(@submission.image(:resized)) }
end
if @folder
  json.submission_folder do
    json.extract! @folder, :id, :name, :url_name
    json.type @folder.class.name
    json.url profile_submission_folder_url(@folder.profile, @folder)
  end
else
  json.submission_folder nil
end
json.collaborators @submission.approved_collaborators do |collaborator|
  json.id collaborator.id
  json.type collaborator.class.name
  json.name collaborator.name
  json.site_identifier collaborator.site_identifier
  json.url profile_home_url(collaborator.site_identifier)
  json.profile_pic do
    json.url paperclip_url(collaborator.default_profile_pic.image.url(:pixels_80))
  end
end
json.in_series @submission.in_series?
if @submission.in_series?
  json.series do
    if @submission.previous_submission
      json.previous do
        json.extract! @submission.previous_submission, :id, :title, :url_title, :width, :height, :published_at
        json.type @submission.previous_submission.class.name
        json.is_adult @submission.previous_submission.is_adult?
        json.url submission_url(@submission.previous_submission)
        json.image do
          json.thumb_96 { json.url paperclip_url(@submission.previous_submission.image(:thumb_96)) }
          json.thumb_240 { json.url paperclip_url(@submission.previous_submission.image(:thumb_240)) }
          json.resized { json.url paperclip_url(@submission.previous_submission.image(:resized)) }
        end
      end
    end
    if @submission.next_submission
      json.next do
        json.extract! @submission.next_submission, :id, :title, :url_title, :width, :height, :published_at
        json.type @submission.next_submission.class.name
        json.is_adult @submission.next_submission.is_adult?
        json.url submission_url(@submission.next_submission)
        json.image do
          json.thumb_96 { json.url paperclip_url(@submission.next_submission.image(:thumb_96)) }
          json.thumb_240 { json.url paperclip_url(@submission.next_submission.image(:thumb_240)) }
          json.resized { json.url paperclip_url(@submission.next_submission.image(:resized)) }
        end
      end
    end
  end
end
if @submission.replyable
  json.replyable do
    json.extract! @submission.replyable, :id, :title, :url_title, :published_at
    json.type @submission.replyable.class.name
    json.url polymorphic_url(@submission.replyable)
  end
else
  json.replyable nil
end
json.replies_count @submission.replies.count
if @submission.replies.count > 0
  json.replies @submission.replies.each do |reply|
    json.extract! reply, :id, :title, :url_title, :published_at
    json.type reply.class.name
    json.url polymorphic_url(reply)
    if !reply.is_a?(Journal)
      json.image do
        json.thumb_96 { json.url paperclip_url(reply.image(:thumb_96)) }
        json.thumb_240 { json.url paperclip_url(reply.image(:thumb_240)) }
        json.resized { json.url paperclip_url(reply.image(:resized)) }
      end
    end
  end
end
json.is_faved current_profile ? current_profile.has_faved?(@submission) : false
json.is_shared current_profile ? current_profile.has_shared?(@submission) : false
if @submission.is_a?(SubmissionGroup)
  json.submissions @submission.submissions.map do |sub|
    json.extract! sub, :id, :width, :height
    json.type sub.class.name
    json.image do
      json.thumb_96  { json.url paperclip_url(sub.image(:thumb_96)) }
      json.thumb_240 { json.url paperclip_url(sub.image(:thumb_240)) }
      json.thumb_400 { json.url paperclip_url(sub.image(:thumb_400)) }
      json.resized   { json.url paperclip_url(sub.image(:resized)) }
    end
  end  
end
json.url submission_url(@submission)
json.comments_url submission_comments_url(@submission)
json.fave_url fave_submission_url(@submission)
json.share_url share_submission_url(@submission)
if !@submission.claimed?
  json.claim_url claim_submission_url(@submission)
end
