json.type @folder.class.name
json.description 'A SubmissionFolder helps organize Submissions for a Profile.'
json.folder {
  json.name {
    json.description 'Folder name.'
    json.type 'String'
    json.required true
    json.max_length 80
  }
  json.filter_ids {
    json.description 'Filters that the Folder is a part of. Submissions will inherit these if added.'
    json.type 'Array/Integers'
    json.required false
  }
}
json.example {
  json.name 'Sketches'
  json.filter_ids [1,2]
}
json.post_url "#{imaginate_host_url}/profiles/{profile_id}/submission_folders"