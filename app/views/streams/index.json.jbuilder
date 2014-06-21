json.array!(@streams) do |stream|
  json.extract! stream, :id, :name, :is_public, :is_permanent, :rules
  json.include_journals stream.include_journals?
  json.following current_profile.following_stream?(stream)
  json.include_submissions stream.include_submissions?
  json.url profile_stream_url(stream.profile, stream)
end
