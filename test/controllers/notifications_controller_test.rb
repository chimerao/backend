require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
  end

  test "index should succeed" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
  end

  test "index json should head forbidden for another profile" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :index, profile_id: @profile
    assert_response :forbidden
  end
end
