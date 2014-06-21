require 'test_helper'

class ProfileTagsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @filter = filters(:dragon_friend_filter)
    @tagged_profile = @lion
    @filter.tag_list.add('friend')
    @filter.save
  end

  test "index" do
    login_user
    set_profile
    get :index, profile_id: @tagged_profile
    assert_response :success
    assert assigns(:tags)
  end

  test "create" do
    login_user
    set_profile
    post :create, profile_id: @tagged_profile, tags: 'friend'
    assert_response :no_content
  end

  test "create should add tag to target profile" do
    login_user
    set_profile
    assert_not @tagged_profile.relations_from(@profile).include?('friend')
    post :create, profile_id: @tagged_profile, tags: 'friend'
    @tagged_profile.reload
    assert @tagged_profile.relations_from(@profile).include?('friend'),
           "tag was not added to target profile"
  end

  test "create tags should add profile to filter if filter tags match" do
    login_user
    set_profile
    assert_not @filter.profiles.include?(@tagged_profile)
    post :create, profile_id: @tagged_profile, tags: 'friend'
    assert @filter.profiles.include?(@tagged_profile),
           "new profile was not added to the filter"
  end

  test "create a new tag should not destroy the old tags" do
    login_user
    set_profile
    @profile.tag(@tagged_profile, with: 'lion', on: :relations)
    post :create, profile_id: @tagged_profile, tags: 'friend'
    @tagged_profile.reload
    assert @tagged_profile.relations_from(@profile).include?('friend'),
           "new tag was not added to target profile"
    assert @tagged_profile.relations_from(@profile).include?('lion'),
           "old tag got removed"
  end

  test "destroy" do
    login_user
    set_profile
    delete :destroy, profile_id: @tagged_profile, id: 'friend'
    assert_response :no_content
  end

  test "destroy should remove tag from target profile" do
    login_user
    set_profile
    @profile.tag(@tagged_profile, with: 'friend', on: :relations)
    assert @tagged_profile.relations_from(@profile).include?('friend')
    delete :destroy, profile_id: @tagged_profile, id: 'friend'
    @tagged_profile.reload
    assert_not @tagged_profile.relations_from(@profile).include?('friend'),
               "tag was not removed"
  end

  test "destroy tags should remove profile from filter if filter tags match" do
    login_user
    set_profile
    @filter.profiles << @tagged_profile
    assert @filter.profiles.include?(@tagged_profile)
    delete :destroy, profile_id: @tagged_profile, id: 'friend'
    assert_not @filter.profiles.include?(@tagged_profile),
               "profile was not removed from the filter"
  end

  test "destroy a tag should not affect other tags" do
    login_user
    set_profile
    @profile.tag(@tagged_profile, with: 'lion,friend', on: :relations)
    delete :destroy, profile_id: @tagged_profile, id: 'friend'
    @tagged_profile.reload
    assert_not @tagged_profile.relations_from(@profile).include?('friend'),
           "tag was not removed"
    assert @tagged_profile.relations_from(@profile).include?('lion'),
           "old tag got removed"
  end
end