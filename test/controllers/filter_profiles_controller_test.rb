require 'test_helper'

class FilterProfilesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @filter = filters(:dragon_friend_filter)
  end

  test "index" do
    login_user
    set_profile
    @filter.add_profile(@raccoon)
    get :index, profile_id: @profile, filter_id: @filter
    assert_response :success
    assert assigns(:members)
  end

  test "index should not work for other profile" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index, profile_id: @profile, filter_id: @filter
    assert_response :forbidden
  end

  test "create" do
    login_user
    set_profile
    assert_not @filter.profiles.include?(@lion)
    post :create, profile_id: @profile, filter_id: @filter, id: @lion
    assert_response :success
    @filter.reload
    assert @filter.profiles.include?(@lion)
    assert assigns(:filter)
  end

  test "create should succeed if name has an at-symbol before it" do
    login_user
    set_profile
    assert_not @filter.profiles.include?(@lion)
    post :create, profile_id: @profile, filter_id: @filter, site_identifier: '@Lion'
    assert_response :success
    @filter.reload
    assert @filter.profiles.include?(@lion)
  end

  test "destroy" do
    @filter.add_profile(@lion)
    login_user
    set_profile
    assert @filter.profiles.include?(@lion)
    delete :destroy, profile_id: @profile, filter_id: @filter, id: @lion
    assert_response :no_content
    @filter.reload
    assert_not @filter.profiles.include?(@lion)
  end


  ##### Approval tests

  def setup_approval_tests
    @profile = @raccoon
    login_user(@lion.user)
    @lion = @lion
    set_profile(@lion)
    @filter = filters(:lion_mane_filter)
    @filter.profile_request(@profile)
    @fp = @filter.filter_profiles.where(profile: @profile).first
  end

  # test "review join" do
  #   setup_approval_tests
  #   get :review_join, profile_id: @lion, filter_id: @filter, id: @profile
  #   assert_response :success
  # end

  test "approve should update filter profile" do
    setup_approval_tests
    post :approve, profile_id: @lion, filter_id: @filter, id: @profile
    assert_response :no_content
    @profile.reload
    assert @profile.profile_filters.include?(@filter),
      "filter profile record was not updated"
    assert @profile.in_filter?(@filter)
  end

  test "approve should remove the associated notification" do
    setup_approval_tests
    before_count = @lion.notifications.count
    assert_difference 'Notification.count', -1 do
      post :approve, profile_id: @lion, filter_id: @filter, id: @profile
    end
    @lion.reload
    assert_equal before_count - 1, @lion.notifications.count
  end

  test "approve should not work for another profile" do
    setup_approval_tests
    login_user(@raccoon.user)
    set_profile(@raccoon)
    post :approve, profile_id: @lion, filter_id: @filter, id: @profile
    assert_not @profile.in_filter?(@filter),
      "another profile was able to access filter approve"
    assert_response :forbidden
  end

  test "decline should destroy filter profile" do
    setup_approval_tests
    assert_difference 'FilterProfile.count', -1 do
      delete :decline, profile_id: @lion, filter_id: @filter, id: @profile
    end
    assert_response :no_content
    @profile.reload
    assert_not @profile.profile_filters.include?(@filter),
      "filter profile record was not removed"
    assert_not @profile.in_filter?(@filter)
  end

  test "decline should remove the associated notification" do
    setup_approval_tests
    before_count = @lion.notifications.count
    assert_difference 'Notification.count', -1 do
      delete :decline, profile_id: @lion, filter_id: @filter, id: @profile
    end    
    @lion.reload
    assert_equal before_count - 1, @lion.notifications.count
  end

  test "decline should not work for another profile" do
    setup_approval_tests
    login_user(@raccoon.user)
    set_profile(@raccoon)
    post :decline, profile_id: @lion, filter_id: @filter, id: @profile
    assert_not @profile.in_filter?(@filter),
      "another profile was able to access filter decline"
    assert_response :forbidden
  end
end
