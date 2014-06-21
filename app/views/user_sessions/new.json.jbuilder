json.description 'Authenticate based on credentials.'
json.login {
  json.identifier {
    json.description 'Unique identifier. Currently username and email are supported.'
    json.type 'String'
    json.required true
  }
  json.password {
    json.description "The User's password."
    json.type 'String'
    json.required true
  }
}
json.example {
  json.identifier 'person@example.com'
  json.password 'MyHopefullyStrongPassword'
}
json.post_url "#{imaginate_host_url}/login"
