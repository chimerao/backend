require 'test_helper'

class SubmissionSharesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:lion_image_1)
  end

  test "share submission" do
    login_user
    set_profile
    assert_difference 'Share.count' do
      post :create, id: @submission
    end
    assert_response :no_content
  end

  test "unshare submission" do
    @profile.shares.create(shareable: @submission)
    login_user
    set_profile
    assert_difference 'Share.count', -1 do
      delete :destroy, id: @submission
    end
    assert_response :no_content
  end

  test "should not be able to share the same submission twice" do
    @profile.shares.create(shareable: @submission)
    login_user
    set_profile
    assert_no_difference 'Share.count' do
      post :create, id: @submission
    end
    assert_response :unprocessable_entity
  end

  test "cannot share while logged out" do
    assert_no_difference 'Share.count' do
      post :create, id: @submission
    end
  end
end