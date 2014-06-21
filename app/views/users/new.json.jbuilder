json.type @user.class.name
json.description 'A User is what authenticates with the site.'
json.user {
  json.username {
    json.description 'A unique identifer for the User.'
    json.type 'String'
    json.required true
    json.max_length 40
  }
  json.email {
    json.description 'Email address for the User.'
    json.type 'String'
    json.required true
    json.max_length 80
  }
  json.password {
    json.description 'I hope you know what this is.'
    json.type 'String'
    json.required true
  }
  json.password_confirmation {
    json.description 'And we need to make sure it is not mistyped. Of course.'
    json.type 'String'
    json.required true
  }
}
json.example {
  json.username 'newuser'
  json.email 'user@example.com'
  json.password 'example'
  json.password_confirmation 'example'
}
json.post_url users_url