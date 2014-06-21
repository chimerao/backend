require 'test_helper'

class SubmissionFoldersControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @folder = submission_folders(:dragon_dragons_folder)    
  end

  test "index" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:folders)
  end

  test "index should not succeed for another profile" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :index, profile_id: @profile
    assert_response :forbidden
  end

  test "show" do
    login_user
    set_profile
    get :show, profile_id: @profile, id: @folder
    assert_response :success
    assert assigns(:folder)
    assert assigns(:submissions)
  end

  test "new" do
    login_user
    set_profile
    get :new, profile_id: @profile
    assert_response :success
    assert assigns(:folder)
  end

  test "create" do
    login_user
    set_profile
    assert_difference 'SubmissionFolder.count' do
      post :create,
           profile_id: @profile,
           submission_folder: {
             name: 'Fat toons'
           }
    end
    assert_response :created
    assert assigns(:folder)
  end

  test "create with filters" do
    login_user
    set_profile
    filter = filters(:dragon_friend_filter)
    assert_difference 'SubmissionFolder.count' do
      post :create,
           profile_id: @profile,
           submission_folder: {
             name: 'Fat toons',
             filter_ids: [
               filter.id
             ]
           }
    end
    assert assigns(:folder).filters.include?(filter)
  end

  test "update" do
    login_user
    set_profile
    assert_equal 'Dragons', @folder.name
    patch :update,
          profile_id: @profile,
          id: @folder,
          submission_folder: {
            name: 'Fat Dragons'
          }
    assert_response :no_content
    @folder.reload
    assert_equal 'Fat Dragons', @folder.name
  end

  test "destroy" do
    login_user
    set_profile
    assert_difference 'SubmissionFolder.count', -1 do
      delete :destroy,
             profile_id: @profile,
             id: @folder
    end
    assert_response :no_content
  end

end
