json.type @profile.class.name
json.description 'A Profile is the main entity on the site.'
json.journal {
  json.name {
    json.description 'The name for the Profile.'
    json.type 'String'
    json.required true
    json.max_length 40
  }
  json.site_identifier {
    json.description 'The unique identifier for the Profile on the site.'
    json.type 'String'
    json.required true
    json.max_length 20
  }
  json.bio {
    json.description 'A short intro for the Profile.'
    json.type 'String'
    json.required false
    json.max_length 160
  }
  json.location {
    json.description 'Where the Profile is located.'
    json.type 'String'
    json.required false
    json.max_length 80
  }
  json.homepage {
    json.description 'The Internet homepage for the Profile.'
    json.type 'String'
    json.required false
    json.max_length 80
  }
  json.description {
    json.description 'A much longer description for the Profile.'
    json.type 'String'
    json.required false
    json.max_length 65000
  }
}
json.example {
  json.name 'Chimera'
  json.site_identifier 'Myth'
  json.bio 'I am never quite sure what to call myself.'
  json.location 'Anytown, Earth'
  json.homepage 'example.com/home'
}
json.post_url "#{imaginate_host_url}/profiles"