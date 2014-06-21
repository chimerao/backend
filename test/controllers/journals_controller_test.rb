require 'test_helper'

class JournalsControllerTest < ActionController::TestCase
  
  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @journal = journals(:dragon_journal_1)
    @private_journal = journals(:dragon_friend_journal_1)
  end

  ## SHOW

  test "show" do
    get :show, id: @journal
    assert_response :success
    assert assigns(:journal)
  end

  test "show on an inaccessable journal should return not found" do
    get :show, id: @private_journal
    assert_response :not_found
  end

  test "show should work logged out" do
    get :show, id: @journal
    assert_response :success
  end

  test "show with a comment on the journal should work" do
    login_user
    set_profile
    Comment.create(profile: @profile, commentable: @journal, body: 'Hey')
    get :show, id: @journal
    assert_response :success
    assert assigns(:comments)
  end

  test "show on a filtered journal should disallow access to a non member of the filter" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :show, id: @private_journal
    assert_response :not_found
  end

  test "show on a filtered journal should allow access to a profile on the filter" do
    @user = users(:lion)
    @profile = profiles(:lion_profile_1)
    filters(:dragon_friend_filter).profiles << @profile
    login_user
    set_profile
    get :show, id: @private_journal
    assert_response :success
  end

  test "show on a filtered journal should allow access to the owner profile" do
    login_user
    set_profile
    get :show, id: @private_journal
    assert_response :success
  end

  test "show should work for logged out users" do
    get :show, id: @journal
    assert_response :success
  end

  test "show on a filtered journal should disallow access to a logged out user" do
    get :show, id: @private_journal
    assert_response :not_found
  end

  test "show should increment views" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :show, id: @journal
    @journal.reload
    assert_equal 1, @journal.views_count,
      "views increased on an unpublished journal"
  end

  test "show should not increment views for the owning profile" do
    login_user
    set_profile
    get :show, id: @journal
    @journal.reload
    assert_equal 0, @journal.views_count,
      "views increased on an unpublished journal"
  end

  test "reply to journal with journal should succeed" do
    journal = journals(:donkey_journal_1)
    login_user
    set_profile
    assert_difference 'Journal.count' do
      post :reply, id: journal, replyable_type: 'journal'
    end
    assert_redirected_to edit_profile_journal_path(@profile, assigns(:reply_journal))
    assert_equal journal, assigns(:reply_journal).replyable,
      "journal was not set on a replyable journal"
  end

  test "reply to journal with submission should succeed" do
    journal = journals(:donkey_journal_1)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :reply, id: journal, replyable_type: 'submission'
    end
    assert_redirected_to edit_profile_submission_path(@profile, assigns(:reply_submission))
    assert_equal journal, assigns(:reply_submission).replyable,
      "journal was not set on a replyable submission"
  end
end