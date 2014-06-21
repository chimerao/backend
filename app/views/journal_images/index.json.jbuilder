json.array!(@journal_images) do |image|
  json.extract! image, :id
  json.image do
    json.pixels_600 { json.url paperclip_url(image.image(:pixels_600)) }
    json.pixels_240 { json.url paperclip_url(image.image(:pixels_240)) }
  end
end
