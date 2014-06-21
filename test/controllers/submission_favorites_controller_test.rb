require 'test_helper'

class SubmissionFavoritesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:lion_image_1)
  end

  test "fave" do
    login_user
    set_profile
    assert_difference 'Favorite.count' do
      post :create, id: @submission
    end
    assert_response :no_content
  end

  test "should not be able to fave the same submission twice" do
    @profile.favorites.create(favable: @submission)
    login_user
    set_profile
    assert_no_difference 'Favorite.count' do
      post :create, id: @submission
    end
    assert_response :no_content
  end

  test "unfave" do
    @profile.favorites.create(favable: @submission)
    login_user
    set_profile
    assert_difference 'Favorite.count', -1 do
      delete :destroy, id: @submission
    end
    assert_response :no_content
  end

  test "cannot fave while logged out" do
    assert_no_difference 'Favorite.count' do
      post :create, id: @submission
    end
  end
end