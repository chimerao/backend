require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  setup do
    setup_json_api
  end

  test "new" do
    get :new
    assert_response :success
  end

  test "create" do
    @user = users(:dragon)
    assert_equal nil, assigns(:current_user)
    post :create, identifier: @user.email, password: 'password'
    assert_response :success
    assert_equal @user, assigns(:current_user)
  end

  test "create should accept username in place of email" do
    @user = users(:dragon)
    assert_equal nil, assigns(:current_user)
    post :create, identifier: @user.username, password: 'password'
    assert_response :success
    assert_equal @user, assigns(:current_user)
  end

  test "create without proper password should fail" do
    assert_not assigns(:current_user)
    post :create, identifier: 'dragon@critters.org', password: 'nopassfoo'
    assert_not assigns(:current_user)
  end

  test "destroy" do
    @user = users(:dragon)
    login_user
    assert_equal @user, assigns(:current_user)
    delete :destroy
    assert_response :no_content
    assert_equal nil, assigns(:current_user)
  end
end