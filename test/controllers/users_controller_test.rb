require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:dragon)
    setup_json_api
  end

  test "new" do
    get :new
    assert_response :success
    assert assigns(:user)
  end

  test "create" do
    assert_difference('User.count') do
      post :create,
           email: 'user@new.com',
           password: 'password',
           password_confirmation: 'password'
    end
    assert_response :created
    assert assigns(:user)
    assert_equal 'user@new.com', assigns(:user).email
  end

  test "update" do
    login_user
    assert_not_equal 'donkey@donk.com', @user.email
    patch :update,
          id: @user,
          email: 'donkey@donk.com'
    assert_response :no_content
    @user.reload
    assert_equal 'donkey@donk.com', @user.email
  end
end
