json.id profile_pic.id
json.type profile_pic.class.name
json.image do
  json.available_sizes ProfilePic::AVAILABLE_PIXEL_SIZES
  json.url paperclip_url(profile_pic.image(:pixels_52)).gsub('pixels_52', 'pixels_{size}')
end