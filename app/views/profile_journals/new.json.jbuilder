json.type @journal.class.name
json.description 'A Journal is a blog post for a Profile.'
json.journal {
  json.title {
    json.description 'Journal title. Required for publishing.'
    json.type 'String'
    json.required false
    json.max_length 80
  }
  json.body {
    json.description 'Primary Journal content. Required for publishing.'
    json.type 'String'
    json.required true
    json.max_length 65000
  }
  json.profile_pic_id {
    json.description 'ID for the ProfilePic to associate with the Journal, if any.'
    json.type 'Integer'
    json.required false
  }
  json.journal_id {
    json.description 'ID of the previous Journal in a series. Will automatically make the Journal part of a series.'
    json.type 'Integer'
    json.required false
  }
  json.tags {
    json.description 'Tags that describe this Journal.'
    json.type 'Array/Strings'
    json.required false
  }
  json.filter_ids {
    json.description 'Filters that the Journal is a part of.'
    json.type 'Array/Integers'
    json.required false
  }
}
json.example {
  json.title 'Hello Internet!'
  json.body 'This is my new journal entry.'
  json.profile_pic_id 1
  json.tags ['api', 'hello world']
  json.filter_ids [1,2]
}
json.post_url "#{imaginate_host_url}/profiles/{profile_id}/journals"