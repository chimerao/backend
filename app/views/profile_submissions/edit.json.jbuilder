json.type @submission.class.name
json.description 'A Submission is a media post for a Profile.'
json.submission {
  json.title {
    json.description 'Submission title. Required for publishing.'
    json.type 'String'
    json.required false
    json.max_length 80
  }
  json.description {
    json.description 'Description of the Submission.'
    json.type 'String'
    json.required false
    json.max_length 65000
  }
  json.owner_id {
    json.description 'ID of the profile that owns the media rights.'
    json.type 'Integer'
    json.required false
  }
  json.submission_id {
    json.description 'ID of the previous Submission in a series. Will automatically make Submission part of a series.'
    json.type 'Integer'
    json.required false
  }
  json.tag_list {
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
  json.submission {
    json.title 'Hello Internet!'
    json.description 'This is my new submission.'
    json.tag_list ['api','hello world']
    json.filter_ids [1,2]
  }
}
json.patch_url profile_submission_url(@profile, @submission)