json.array!(@profile_pics) do |profile_pic|
  json.extract! profile_pic, :id, :title, :is_default
  json.type profile_pic.class.name
  json.url profile_pic_url(@profile, profile_pic)
  json.image do
    json.available_sizes ProfilePic::AVAILABLE_PIXEL_SIZES
    json.url paperclip_url(profile_pic.image(:pixels_52)).gsub('pixels_52', 'pixels_{size}')
  end
end