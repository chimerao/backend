json.type @folder.class.name
json.description 'A FavoriteFolder helps organize Submissions for a Profile.'
json.folder {
  json.name {
    json.description 'Folder name.'
    json.type 'String'
    json.required true
    json.max_length 80
  }
  json.is_private {
    json.description 'The Folder will be visiable only to the owning Profile.'
    json.type 'Boolean'
    json.default false
    json.required false
  }
}
json.example {
  json.submission_folder {
    json.name 'Baseball'
    json.is_private false
  }
}
json.post_url "#{imaginate_host_url}/profiles/{profile_id}/favorite_folders"