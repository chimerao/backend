json.type @stream.class.name
json.description 'A Stream is a filter for site data'
json.stream {
  json.name {
    json.description 'Stream name.'
    json.type 'String'
    json.required true
    json.max_length 40
  }
  json.include_journals {
    json.description 'Include Journals in the stream.'
    json.type 'Boolean'
    json.required false
  }
  json.include_submissions {
    json.description 'Include Submissions in the stream.'
    json.type 'Boolean'
    json.required false
  }
  json.tags {
    json.description 'Tags to filter the stream by.'
    json.type 'Array/Strings'
    json.required false
  }
  json.is_public {
    json.description 'Will the stream be viewable by others?'
    json.type 'Boolean'
    json.required false
  }
}
json.example {
  json.name 'Mythological Creatures'
  json.include_submissions true
  json.tags ['chimera', 'griffin', 'dragon']
  json.is_public true
}
json.post_url new_profile_stream_url(current_profile)