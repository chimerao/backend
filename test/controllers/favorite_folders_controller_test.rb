require 'test_helper'

class FavoriteFoldersControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @raccoon
    @user = @profile.user
    @folder = favorite_folders(:raccoon_raccoons_folder)
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
    assert_difference 'FavoriteFolder.count' do
      post :create,
           profile_id: @profile,
           favorite_folder: {
             name: 'Fat toons'
           }
    end
    assert_response :created
    assert assigns(:folder)
  end

  test "update" do
    login_user
    set_profile
    assert_equal 'Raccoons', @folder.name
    patch :update,
          profile_id: @profile,
          id: @folder,
          favorite_folder: {
            name: 'Fat Raccoons',
            is_private: true
          }
    assert_response :no_content
    @folder.reload
    assert_equal 'Fat Raccoons', @folder.name
    assert @folder.is_private?
  end

  test "destroy" do
    login_user
    set_profile
    assert_difference 'FavoriteFolder.count', -1 do
      delete :destroy,
             profile_id: @profile,
             id: @folder
    end
    assert_response :no_content
  end
end