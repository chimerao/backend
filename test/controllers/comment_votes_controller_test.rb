require 'test_helper'

class CommentVotesControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:lion_image_1)
    @comment = comments(:lion_on_lion_image_1)    
  end

  test "create comment" do
    login_user
    set_profile(@profile)
    assert_difference 'Vote.count' do
      post :create, id: @comment
    end
    assert_response :no_content
  end

  test "create should not succeed while out" do
    assert_no_difference 'Vote.count' do
      post :create, id: @comment
    end
  end

  test "create should not succeed if profile already voted" do
    @profile.votes.create(votable: @comment)
    login_user
    set_profile(@profile)
    assert_no_difference 'Vote.count' do
      post :create, id: @comment
    end
    assert_response :unprocessable_entity
  end

  test "destroy" do
    @profile.votes.create(votable: @comment)
    login_user
    set_profile(@profile)
    assert_difference 'Vote.count', -1 do
      delete :destroy, id: @comment
    end
    assert_response :no_content
  end

  test "destroy should not succeed while logged out" do
    @profile.votes.create(votable: @comment)
    assert_no_difference 'Vote.count' do
      delete :destroy, id: @comment
    end
  end
end