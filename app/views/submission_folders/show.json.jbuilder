json.extract! @folder, :id, :name, :url_name, :created_at
json.type @folder.class.name
json.filters @folder.filters do |filter|
  json.extract! filter, :id, :name
end
json.url profile_submission_folder_url(@profile, @folder)
json.submissions @submissions do |submission|
  json.extract! submission, :id, :title, :url_title, :description, :width, :height, :favorites_count, :comments_count, :shares_count, :views_count, :published_at
  json.type 'Submission'
  json.is_adult submission.is_adult?
  json.url submission_url(submission)
  json.image do
    json.thumb_64 { json.url paperclip_url(submission.file.url(:thumb_64)) }
    json.thumb_96 { json.url paperclip_url(submission.file.url(:thumb_96)) }
    json.thumb_240 { json.url paperclip_url(submission.file.url(:thumb_240)) }
    json.thumb_400 { json.url paperclip_url(submission.file.url(:thumb_400)) }
  end
  json.in_series submission.in_series?
end