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
           user: { 
             username: 'newuser',
             email: 'user@new.com',
             password: 'password',
             password_confirmation: 'password'
           }
    end
    assert_response :created
    assert assigns(:user)
  end

  test "update" do
    login_user
    assert_not_equal 'donkey', @user.username
    patch :update,
          id: @user,
          user: {
            username: 'donkey'
          }
    assert_response :no_content
    @user.reload
    assert_equal 'donkey', @user.username
  end
end
