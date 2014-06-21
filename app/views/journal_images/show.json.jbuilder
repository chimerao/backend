json.extract! @journal_image, :id
json.image do
  json.pixels_600 { json.url paperclip_url(@journal_image.image(:pixels_600)) }
  json.pixels_240 { json.url paperclip_url(@journal_image.image(:pixels_240)) }
end
