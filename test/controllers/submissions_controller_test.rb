require 'test_helper'

class SubmissionsControllerTest < ActionController::TestCase
  
  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:dragon_image_1)
    @private_submission = submissions(:dragon_friend_submission_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    @collaborator = @lion
    @collaboration_submission = submissions(:dragon_lion_collaboration_image_1)
  end

  ###################################################################
  ## INDEX
  ###################################################################

  test "index" do
    get :index
    assert_response :success
    assert_not assigns(:profile)
  end

  test "index should not show private submissions to logged out users" do
    get :index
    assert_response :success
    assert_not assigns(:submissions).include?(@private_submission),
               "logged out user saw a private submission in a collection"
  end

  test "index should not show private submissions to profiles" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :index
    assert_response :success
    assert_not assigns(:submissions).include?(@private_submission),
               "a profile saw a private submission in a collection they shouldn't have"
  end

  test "index should show private submissions to submission owner" do
    login_user
    set_profile(@profile)
    get :index
    assert assigns(:submissions).include?(@private_submission),
           "owner did not see their own private submission"
  end

  test "index should show private submissions to submission collaborators" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    Collaboration.create!(profile: profile, submission: @private_submission)
    get :index
    assert_response :success
    assert assigns(:submissions).include?(@private_submission),
           "collaborator did not see a private submission they were part of"
  end

  test "index should not include unpublished submissions" do
    get :index
    assert_response :success
    assert_not assigns(:submissions).include?(@unpublished_submission),
               "an unpublished submission was shown"
  end

  test "index pagination" do
    get :index
    assert_response :success
    assert_equal 7, assigns(:submissions).size

    get :index, per_page: 2
    assert_response :success
    assert_equal 2, assigns(:submissions).size
    assert assigns(:submissions).include?(@submission)

    get :index, per_page: 2, page: 2
    assert_response :success
    assert_equal 2, assigns(:submissions).size
    assert_not assigns(:submissions).include?(@submission)
  end

  test "index pagination for profile" do
    login_user
    set_profile
    get :index
    assert_response :success
    assert_equal 7, assigns(:submissions).size

    get :index, per_page: 2
    assert_equal 2, assigns(:submissions).size
    assert assigns(:submissions).include?(@submission)

    get :index, per_page: 2, page: 2
    assert_equal 2, assigns(:submissions).size
    assert_not assigns(:submissions).include?(@submission)
  end

  ###################################################################
  ## SHOW
  ###################################################################

  test "show" do
    login_user
    set_profile
    get :show, id: @submission
    assert_response :success
    assert assigns(:submission)
    assert assigns(:comment)
  end

  test "show with a comment on the submission should work" do
    login_user
    set_profile
    Comment.create!(profile: @profile, commentable: @submission, body: 'Hey')
    get :show, id: @submission
    assert_response :success
    assert assigns(:comments)
  end

  test "show on a filtered submission should disallow access to a non member of the filter" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :show, id: @private_submission
    assert_response :redirect
  end

  test "show on a filtered submission should allow access to a profile on the filter" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    filters(:dragon_friend_filter).profiles << profile
    get :show, id: @private_submission
    assert_response :success
  end

  test "show on a filtered submission should allow access to the owner profile" do
    login_user
    set_profile
    get :show, id: @private_submission
    assert_response :success
  end

  test "show on a filtered submission should allow access to a collaborator" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    Collaboration.create!(profile: profile, submission: @private_submission)
    get :show, id: @private_submission
    assert_response :success
  end

  test "show should work for logged out users" do
    get :show, id: @submission
    assert_response :success
  end

  test "show submissions with comments should work for logged out users" do
    get :show, id: submissions(:lion_image_1)
    assert_response :success
  end

  test "show on a filtered submission should disallow access to a logged out user" do
    get :show, id: @private_submission
    assert_response :redirect
  end

  test "show should not display an unpublished image to a logged out user" do
    get :show, id: @unpublished_submission
    assert_response :redirect
  end

  test "show should not display an unpublished image to a non-collaborator" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :show, id: @unpublished_submission
    assert_response :redirect
  end

  test "show should allow access to the submission owner" do
    login_user
    set_profile
    get :show, id: @unpublished_submission
    assert_response :success
  end

  test "show should allow access to a submission collaborator" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    @unpublished_submission.add_collaborator(profile)
    get :show, id: @unpublished_submission
    assert_response :success
  end

  # It should act as if that submission doesn't exist
  test "show should not show an individual submission that is part of a group" do
    login_user
    set_profile
    submission = submissions(:lion_image_1)
    sg = SubmissionGroup.create(profile: profiles(:lion_profile_1))
    sg.add_submission(submission)
    get :show, id: submission
    assert_response :redirect
  end

  test "show should increment views" do
    login_user(users(:lion))
    set_profile(profiles(:lion_profile_1))
    get :show, id: @submission
    @submission.reload
    assert_equal 1, @submission.views_count,
      "views did not increase"
  end

  test "show should not increment views for the owning profile" do
    login_user
    set_profile
    get :show, id: @submission
    @submission.reload
    assert_equal 0, @submission.views_count,
      "views increased whe the owner viewed the submission"
  end

  test "show should not increment views if submission is unpublished" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    @unpublished_submission.add_collaborator(profile)
    get :show, id: @unpublished_submission
    @unpublished_submission.reload
    assert_equal 0, @unpublished_submission.views_count,
      "views increased on an unpublished submission"
  end

  test "show incrementing views should not add collaborators" do
    raccoon = profiles(:raccoon_profile_1)
    @submission.update_attribute(:description, "A picture for @Raccoon.")
    @submission.remove_collaborator(raccoon)
    assert_not @submission.collaborators.include?(raccoon)
    get :show, id: @submission
    @submission.reload
    assert_not @submission.collaborators.include?(raccoon),
      "tagged profile got added to collaborators after views increment"
  end

  ###################################################################
  ## TAGGED
  ###################################################################

  test "tagged submissions" do
    get :tagged, tag_name: 'dragon'
    assert_response :success
    assert_equal 0, assigns(:submissions).size
    @submission.tag_list.add('dragon')
    @submission.save
    get :tagged, tag_name: 'dragon'
    assert_response :success
    assert_equal 1, assigns(:submissions).size
  end

  test "tagged should not show filtered submissions" do
    login_user(users(:raccoon))
    set_profile(profiles(:raccoon_profile_1))
    @private_submission.tag_list.add('dragon')
    @private_submission.save
    get :tagged, tag_name: 'dragon'
    assert_not assigns(:submissions).include?(@private_submission),
      "a filtered submissions was shown in results"
  end

  test "tagged should not show unpublished submissions" do
    login_user(users(:raccoon))
    set_profile(profiles(:raccoon_profile_1))
    @unpublished_submission.tag_list.add('dragon')
    @unpublished_submission.save
    get :tagged, tag_name: 'dragon'
    assert_not assigns(:submissions).include?(@unpublished_submission),
      "an unpublished submissions was shown in results"
  end

  test "tagged should not show filtered submissions for logged out users" do
    @private_submission.tag_list.add('dragon')
    @private_submission.save
    get :tagged, tag_name: 'dragon'
    assert_not assigns(:submissions).include?(@private_submission),
      "a filtered submissions was shown in results"
  end

  test "tagged should not show unpublished submissions for logged out users" do
    @unpublished_submission.tag_list.add('dragon')
    @unpublished_submission.save
    get :tagged, tag_name: 'dragon'
    assert_not assigns(:submissions).include?(@unpublished_submission),
      "an unpublished submissions was shown in results"
  end

  ###################################################################
  ## REPLY
  ###################################################################

  # test "reply to submission with journal should succeed" do
  #   login_user(users(:lion))
  #   profile = profiles(:lion_profile_1)
  #   set_profile(profile)
  #   assert_difference 'Journal.count' do
  #     get :reply, id: @submission, replyable_type: 'journal'
  #   end
  #   assert_redirected_to edit_profile_journal_path(profile, assigns(:reply_journal))
  #   assert_equal @submission, assigns(:reply_journal).replyable,
  #     "submission was not set on a replyable journal"
  # end

  # test "reply to submission with submission should succeed" do
  #   login_user(users(:lion))
  #   profile = profiles(:lion_profile_1)
  #   set_profile(profile)
  #   get :reply, id: @submission, replyable_type: 'submission'
  #   assert_response :success
  #   assert_equal @submission, assigns(:submission).replyable,
  #     "submission was not set on a replyable submission"
  # end

  # test "reply to unaccessible submission should redirect" do
  #   login_user(users(:lion))
  #   profile = profiles(:lion_profile_1)
  #   set_profile(profile)
  #   get :reply, id: @private_submission, replyable_type: 'submission'
  #   assert_response :redirect
  # end

  ###################################################################
  ## COLLABORATOR APPROVAL (APPROVAL, APPROVE, DECLINE)
  ###################################################################

  # test "approval should succeed for a collaborator" do
  #   login_user(users(:lion))
  #   set_profile(@collaborator)
  #   get :approval, id: @collaboration_submission
  #   assert_response :success
  #   @collaboration_submission.reload
  #   assert_not @collaboration_submission.approved_collaborators.include?(@collaborator),
  #     "profile was set as collaborator when they should not have"
  # end

  test "approval should not succeed for a non-collaborator" do
    login_user
    set_profile(profiles(:dragon_profile_2))
    get :approval, id: @collaboration_submission
    assert_response :forbidden
  end

  test "approve should set collaborator as approved" do
    login_user(users(:lion))
    set_profile(@collaborator)
    post :approve, id: @collaboration_submission
    assert_response :no_content
    @collaboration_submission.reload
    assert @collaboration_submission.approved_collaborators.include?(@collaborator),
      "profile not set as collaborator when they should have been"
  end

  test "approve should remove the appropriate notification" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Notification.count', -1 do
      post :approve, id: @collaboration_submission
    end
  end

  test "approve should not work for a non-collaborator" do
    login_user
    profile = profiles(:dragon_profile_2)
    set_profile(profile)
    get :approve, id: @collaboration_submission
    assert_response :forbidden
    @collaboration_submission.reload
    assert_not @collaboration_submission.approved_collaborators.include?(profile)
  end

  test "approve with profile should switch collaboration to new profile" do
    login_user
    set_profile
    donkey = profiles(:dragon_profile_2)
    lion_submission = submissions(:lion_image_1)
    lion_submission.add_collaborator(@profile)
    post :approve, id: lion_submission, profile: { id: donkey.id }
    assert_response :no_content
    lion_submission.reload
    assert_not lion_submission.approved_collaborators.include?(@profile),
      "profile was set as collaborator when they should not have been"
    assert lion_submission.approved_collaborators.include?(donkey),
      "profile was not set a collaborator but should have been"
  end

  test "approve with profile should not allow an unowned profile to be set" do
    login_user
    set_profile
    raccoon = profiles(:raccoon_profile_1)
    lion_submission = submissions(:lion_image_1)
    lion_submission.add_collaborator(@profile)
    post :approve, id: lion_submission, profile: { id: raccoon.id }
    lion_submission.reload
    assert_not lion_submission.approved_collaborators.include?(raccoon),
      "unowned profile was not set a collaborator but should have been"
    assert lion_submission.approved_collaborators.include?(@profile),
      "profile was set as collaborator when they should not have been"
  end

  test "decline should remove the collaboration" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Collaboration.count', -1 do
      delete :decline, id: @collaboration_submission
    end
    assert_response :no_content
    @collaboration_submission.reload
    assert_not @collaboration_submission.collaborators.include?(@collaborator),
      "profile not removed as collaborator when they should have been"
    assert_not @collaboration_submission.approved_collaborators.include?(@collaborator),
      "profile not removed as an approved collaborator when they should have been"
  end

  test "decline should remove the appropriate notification" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Notification.count', -1 do
      delete :decline, id: @collaboration_submission
    end
  end

  ###################################################################
  ## OWNERSHIP (REQUEST, CLAIM, REVIEW, RELINQUISH)
  ###################################################################

  # test "request claim should succeed" do
  #   login_user(users(:lion))
  #   set_profile(@collaborator)
  #   get :request_claim, id: @collaboration_submission
  #   assert_response :no_content
  # end

#  test "request claim should not allow a non-collaborator access" do
#    login_user(users(:raccoon))
#    set_profile(profiles(:raccoon_profile_1))
#    get :request_claim, id: @collaboration_submission
#    assert_redirected_to dash_path
#  end

  test "claim should send a notification to submission owner" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Notification.count' do
      post :claim, id: @collaboration_submission
    end
    assert_response :no_content
  end

#  test "claim should not allow a non-collaborator access" do
#    login_user(users(:raccoon))
#    set_profile(profiles(:raccoon_profile_1))
#    post :claim, id: @collaboration_submission
#    assert_redirected_to dash_path
#  end

  # test "review relinquish should succeed" do
  #   login_user
  #   set_profile
  #   @collaborator.claims!(@collaboration_submission)
  #   get :review_relinquish, id: @collaboration_submission
  #   assert_response :success
  # end

  test "review relinquish should not work for anyone but the submission parent profile" do
    login_user(users(:raccoon))
    set_profile(profiles(:raccoon_profile_1))
    get :review_relinquish, id: @collaboration_submission
    assert_response :forbidden
    login_user(users(:lion))
    set_profile(@collaborator)
    get :review_relinquish, id: @collaboration_submission
    assert_response :forbidden
  end

  test "relinquish should transfer ownership to claimee" do
    login_user
    set_profile
    @collaborator.claims!(@collaboration_submission)
    post :relinquish, id: @collaboration_submission
    assert_response :no_content
    @collaboration_submission.reload
    assert_equal @collaborator, @collaboration_submission.profile,
      "ownership was not transferred"
  end

  test "relinquish should not work for anyone but the submission parent profile" do
    login_user(users(:raccoon))
    set_profile(profiles(:raccoon_profile_1))
    post :relinquish, id: @collaboration_submission
    assert_response :forbidden
    login_user(users(:lion))
    set_profile(@collaborator)
    post :relinquish, id: @collaboration_submission
    assert_response :forbidden
  end


  ###################################################################
  ## JSON API
  ###################################################################

  test "json index" do
    get :index
    assert_response :success
    assert assigns(:submissions)
  end

  test "json show" do
    get :show, id: @submission
    assert_response :success
    assert assigns(:submission)
  end

  test "json tagged" do
    get :tagged, tag_name: 'lion'
    assert_response :success
    assert assigns(:submissions)
  end

  test "json approve should return no content" do
    login_user(users(:lion))
    set_profile(@collaborator)
    post :approve, id: @collaboration_submission
    assert_response :no_content
    @collaboration_submission.reload
    assert @collaboration_submission.approved_collaborators.include?(@collaborator),
      "profile not set as collaborator when they should have been"
  end

  test "json decline should return no content" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Collaboration.count', -1 do
      delete :decline, id: @collaboration_submission
    end
    assert_response :no_content
    @collaboration_submission.reload
    assert_not @collaboration_submission.collaborators.include?(@collaborator),
      "profile not removed as collaborator when they should have been"
    assert_not @collaboration_submission.approved_collaborators.include?(@collaborator),
      "profile not removed as an approved collaborator when they should have been"
  end

  test "json claim" do
    login_user(users(:lion))
    set_profile(@collaborator)
    assert_difference 'Notification.count' do
      post :claim, id: @collaboration_submission
    end
    assert_response :no_content
  end

  test "json relinquish" do
    login_user
    set_profile
    @collaborator.claims!(@collaboration_submission)
    post :relinquish, id: @collaboration_submission
    assert_response :no_content
    @collaboration_submission.reload
    assert_equal @collaborator, @collaboration_submission.profile,
      "ownership was not transferred"
  end

end
