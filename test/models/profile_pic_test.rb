require 'test_helper'

class ProfilePicTest < ActiveSupport::TestCase

  setup do
    @profile = profiles(:dragon_profile_1)
    @pic = profile_pics(:dragon_profile_pic_1)
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chimera-240.jpg')
  end

  test "make default" do
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    new_pic = ProfilePic.create(profile: @profile, image: image)
    assert_not new_pic.is_default?
    assert @pic.is_default?
    new_pic.make_default!
    @pic.reload
    new_pic.reload
    assert new_pic.is_default?,
      "new profile pic was not set to default"
    assert_not @pic.is_default?,
      "old profile pic is still set default"
  end

  test "after create make default if there are no other pics set default" do
    @profile = profiles(:raccoon_profile_1)
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    @pic = ProfilePic.create(profile: @profile, image: image)
    assert @pic.is_default?,
      "only profile pic was not set to default"
  end

  test "after destroy make sure a default gets set if default gets destroyed" do
    new_pic = profile_pics(:dragon_profile_pic_2)
    assert_not new_pic.is_default?
    assert @pic.is_default?
    @pic.destroy
    new_pic.reload
    assert new_pic.is_default?,
      "a new default profile pic was not set"
  end

  test "ensure default pic should still work if no profile pics remain" do
    assert_difference 'ProfilePic.count', -1 do
      @pic.destroy
    end
  end

end
