json.array!(@submissions) do |submission|
  json.extract! submission, :id, :title, :url_title, :profile_id, :width, :height, :favorites_count, :comments_count, :shares_count, :views_count, :published_at, :updated_at
  json.type submission.class.name
  json.description submission.description ? submission.description.truncate(200) : nil
  json.is_adult submission.is_adult?
  json.url submission_url(submission)
  json.image do
    json.thumb_64  { json.url paperclip_url(submission.image(:thumb_64)) }
    json.thumb_96  { json.url paperclip_url(submission.image(:thumb_96)) }
    json.thumb_180 { json.url paperclip_url(submission.image(:thumb_180)) }
    json.thumb_240 { json.url paperclip_url(submission.image(:thumb_240)) }
    json.thumb_400 { json.url paperclip_url(submission.image(:thumb_400)) }
    json.resized   { json.url paperclip_url(submission.image(:resized)) }
  end
  json.tags submission.tag_list
  if submission.profile == current_profile
    json.filters submission.filters.map { |filter| filter.id }
  end
  json.in_series submission.in_series?
  json.replies_count submission.replies.count
  if submission.is_a?(SubmissionGroup)
    json.submissions submission.submissions.map do |sub|
      json.extract! sub, :id, :width, :height
      json.type sub.class.name
      json.image do
        json.thumb_64  { json.url paperclip_url(sub.image(:thumb_64)) }
        json.thumb_96  { json.url paperclip_url(sub.image(:thumb_96)) }
        json.thumb_180 { json.url paperclip_url(sub.image(:thumb_180)) }
        json.thumb_240 { json.url paperclip_url(sub.image(:thumb_240)) }
        json.thumb_400 { json.url paperclip_url(sub.image(:thumb_400)) }
        json.resized   { json.url paperclip_url(sub.image(:resized)) }
      end
    end  
  end
end
