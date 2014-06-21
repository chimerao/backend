require 'test_helper'

class StreamFavoritesControllerTest < ActionController::TestCase
  
  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @stream = streams(:dragon_public_dragon_stream)
  end
  
  test "fave" do
    login_user
    set_profile(@profile)
    assert_difference 'Favorite.count' do
      post :create, profile_id: @profile, id: @stream
    end
    assert_response :no_content
  end

  test "unfave" do
    @profile.favorites.create(favable: @stream)
    login_user
    set_profile(@profile)
    assert_difference 'Favorite.count', -1 do
      delete :destroy, profile_id: @profile, id: @stream
    end
    assert_response :no_content
  end

  test "fave stream should not work if stream is private" do
    stream = streams(:dragon_private_fatty_stream)
    login_user
    set_profile(@profile)
    assert_no_difference 'Favorite.count' do
      post :create, profile_id: @profile, id: stream
    end
  end
end