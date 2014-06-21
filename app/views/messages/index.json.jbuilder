json.array!(@messages) do |message|
  json.extract! message, :id, :subject, :body, :created_at, :unread, :deleted
  json.url profile_message_url(current_profile, message)
  json.sender do
    json.id message.sender.id
    json.type message.sender.class.name
    json.name message.sender.name
    json.site_identifier message.sender.site_identifier
    json.url profile_url(message.sender)
    json.profile_pic do
      json.partial! 'profile_pics/profile_pic', profile: message.sender, profile_pic: message.profile_pic || message.sender.default_profile_pic
    end
  end
end
