require 'test_helper'

class SubmissionCommentsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:dragon_image_1)
  end

  test "index" do
    get :index,
        submission_id: submissions(:lion_image_1)
    assert_response :success
    assert assigns(:comments)
  end

  test "create" do
    login_user
    set_profile
    assert_difference 'Comment.count' do
      post :create,
           submission_id: @submission.id,
           comment: { body: 'This is neat.' }
    end
    assert_response :created
    assert assigns(:comment)
  end

  test "create without login should fail" do
    assert_no_difference 'Comment.count' do
      post :create,
           submission_id: @submission.id,
           comment: { body: 'This is neat.' }
    end
    assert_response :unauthorized
  end

  test "create without body should fail" do
    login_user
    set_profile
    assert_no_difference 'Comment.count' do
      post :create,
           submission_id: @submission.id,
           comment: { profile_pic_id: profile_pics(:dragon_profile_pic_1).id }
    end
    assert_response :unprocessable_entity
  end

  test "destroy" do
    @user = users(:lion)
    @profile = profiles(:lion_profile_1)
    login_user
    set_profile
    @submission = submissions(:lion_image_1)
    @comment = comments(:lion_on_lion_image_1)
    assert_difference 'Comment.count', -1 do
      delete :destroy,
             submission_id: @submission,
             id: @comment
    end
    assert_response :no_content
  end

  test "destroy own comment on another's submission should succeed" do
    login_user
    set_profile
    assert_difference 'Comment.count', -1 do
      delete :destroy,
             submission_id: submissions(:lion_image_1),
             id: comments(:dragon_on_lion_image_1)
      assert_response :success
    end
  end

  test "destroy without login should fail" do
    assert_no_difference 'Comment.count' do
      delete :destroy,
             submission_id: submissions(:lion_image_1),
             id: comments(:dragon_on_lion_image_1)
      assert_response :unauthorized
    end
  end

  test "destroy another's comment on owned submission should succeed" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    assert_difference 'Comment.count', -1 do
      delete :destroy,
             submission_id: submissions(:lion_image_1),
             id: comments(:dragon_on_lion_image_1)
      assert_response :success
    end
  end

  test "destroy another's comment on unowned submission should fail" do
    login_user
    set_profile
    assert_no_difference 'Comment.count' do
      delete :destroy,
             submission_id: submissions(:lion_image_1),
             id: comments(:lion_on_lion_image_1)
      assert_response :forbidden
    end
  end
end