require 'test_helper'

class FiltersControllerTest < ActionController::TestCase

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
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:filters)
  end

  test "index another profile should only show opt in filters" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    @test_filter = filters(:dragon_fatty_filter)
    get :index, profile_id: @profile
    assert_response :success
    assert_equal 0, assigns(:filters).size
    @test_filter.update_attribute(:opt_in, true)
    get :index, profile_id: @profile
    assert_equal 1, assigns(:filters).size
    assert assigns(:filters).include?(@test_filter),
      "opt in filter was not included"
  end

  test "show" do
    login_user
    set_profile
    get :show, profile_id: @profile, id: @filter
    assert_response :success
    assert assigns(:filter)
  end

  test "new" do
    login_user
    set_profile
    get :new, profile_id: @profile
    assert_response :success
    assert assigns(:filter)
  end

  test "create" do
    login_user
    set_profile
    assert_difference 'Filter.count' do
      post :create,
           profile_id: @profile,
           name: 'Donkeys'
    end
    assert_response :created
    assert assigns(:filter)
  end

  test "update" do
    login_user
    set_profile
    assert_equal 'Friends', @filter.name
    patch :update,
          profile_id: @profile,
          id: @filter,
          name: 'Fuzzies'
    assert_response :no_content
    @filter.reload
    assert_equal 'Fuzzies', @filter.name
    assert assigns(:filter)
  end

  test "destroy" do
    @filter = Filter.create(profile: @profile, name: 'Donkeys')
    login_user
    set_profile
    assert_difference 'Filter.count', -1 do
      delete :destroy,
             profile_id: @profile,
             id: @filter
    end
    assert_response :no_content
  end

  test "join should create a filter profile record" do
    login_user
    set_profile
    before_count = @lion.notifications.count
    @filter = filters(:lion_mane_filter)
    assert_difference 'FilterProfile.count' do
      post :join, profile_id: @lion, id: @filter
    end
    assert_response :no_content
    @lion.reload
    assert_equal before_count + 1, @lion.notifications.count
  end

  test "join" do
    login_user
    set_profile
    @filter = filters(:lion_mane_filter)
    assert_difference 'FilterProfile.count' do
      post :join, profile_id: @lion, id: @filter
    end
    assert_response :no_content
  end

  test "join should create notification" do
    login_user
    set_profile
    before_count = @lion.notifications.count
    @filter = filters(:lion_mane_filter)
    assert_difference 'Notification.count' do
      post :join, profile_id: @lion, id: @filter
    end
    @lion.reload
    assert_equal before_count + 1, @lion.notifications.count
  end

  test "leave" do
    @filter = filters(:lion_mane_filter)
    @filter.profile_request(@profile)
    login_user
    set_profile
    delete :leave,
           profile_id: profiles(:lion_profile_1),
           id: @filter
    assert_response :no_content
  end

  test "leave should remove the profile from the filter" do
    profile = profiles(:lion_profile_1)
    @filter = filters(:lion_mane_filter)
    @filter.profile_request(@profile)
    login_user
    set_profile
    delete :leave, profile_id: profile, id: @filter
    assert_response :no_content
    @filter.reload
    @profile.reload
    assert_not @filter.profiles.include?(@profile)
  end

  test "leave should remove any associated notifications" do
    profile = profiles(:lion_profile_1)
    @filter = filters(:lion_mane_filter)
    @filter.profile_request(@profile)
    login_user
    set_profile
    before_count = profile.notifications.count
    assert_difference 'Notification.count', -1 do
      delete :leave, profile_id: profile, id: @filter
    end
    assert_equal before_count - 1, profile.notifications.count
  end
end