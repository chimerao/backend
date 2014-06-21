json.type @message.class.name
json.description 'A private Message from one Profile to another.'
json.message {
  json.recipient_id {
    json.description 'ID for the Profile the message is being sent to.'
    json.type 'Integer'
    json.required true
  }
  json.subject {
    json.description 'The subject of the Message.'
    json.type 'String'
    json.required false
    json.max_length 120
  }
  json.body {
    json.description 'The main body of the Message.'
    json.type 'String'
    json.required true
    json.max_length 10000
  }
  json.profile_pic_id {
    json.description 'ID for the ProfilePic to associate with the Message, if any.'
    json.type 'Integer'
    json.required false
  }
}
json.example {
  json.message {
    json.recipient_id 1
    json.subject 'Hello there!'
    json.body 'How is your day going?'
    json.profile_pic_id 1
  }
}
json.post_url "#{imaginate_host_url}/profiles/{profile_id}/messages"