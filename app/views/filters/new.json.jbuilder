json.type @filter.class.name
json.description 'A Filter helps organize content to other Profiles.'
json.filter {
  json.name {
    json.description 'Filter name.'
    json.type 'String'
    json.required true
    json.max_length 30
  }
  json.description {
    json.description 'A description of the Filter. Useful for opt-in ones.'
    json.type 'String'
    json.required false
    json.max_length 255
  }
  json.opt_in {
    json.description 'If the Filter is opt-in, others can see and request to join them.'
    json.type 'Boolean'
    json.default false
    json.required false
  }
}
json.example {
  json.name 'Friends'
  json.description 'For people I know.'
  json.opt_in false
}
json.post_url "#{imaginate_host_url}/profiles/{profile_id}/filters"