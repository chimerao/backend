require 'test_helper'

class ProfileSubmissionsControllerTest < ActionController::TestCase

  setup do
    setup_json_api
    setup_default_profiles
    @profile = @dragon
    @user = @profile.user
    @submission = submissions(:dragon_image_1)
    @private_submission = submissions(:dragon_friend_submission_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    @collaboration_submission = submissions(:dragon_lion_collaboration_image_1)
    @group_submission = submissions(:dragon_group_submission_1)
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'FLCL.jpg')
  end

  ###################################################################
  ## INDEX
  ###################################################################

  test "index" do
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:submissions)
  end

  test "index should show to logged out users" do
    get :index, profile_id: @profile
    assert_response :success
  end

  test "index should include a profile" do
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:profile), "@profile doesn't exist in profile submissions path"
  end

  test "index should not show private submissions to logged out users" do
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(@private_submission),
               "logged out user saw a private submission in a collection"
  end

  test "index should not show private submissions to other profiles" do
    login_user(@lion.user)
    set_profile(@lion)
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(@private_submission),
               "a profile saw a private submission in a collection they shouldn't have"
  end

  test "index should show private submissions to submission owner" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert assigns(:submissions).include?(@private_submission),
           "owner did not see their own private submission"
  end

  test "index should show private submissions to submission collaborators" do
    login_user(@lion.user)
    profile = @lion
    @private_submission.add_collaborator(profile)
    set_profile(profile)
    get :index, profile_id: @profile
    assert_response :success
    assert assigns(:submissions).include?(@private_submission),
           "collaborator did not see a private submission they were part of"
  end

  test "index should not include unpublished submissions" do
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(@unpublished_submission),
               "an unpublished submission was shown"
  end

  test "index for profiles should not include submissions within a group" do
    login_user
    set_profile
    get :index, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(submissions(:dragon_group_image_1))
  end

  # Pagination

  test "index should paginate for logged out users" do
    get :index,
        profile_id: @profile,
        per_page: 2

    assert_response :success
    submissions = assigns(:submissions)
    assert_equal 2, submissions.size
    # assert submissions.include?(@group_submission)
    # assert submissions.include?(@submission)
  end

  test "index pagination for profile" do
    login_user
    set_profile
    get :index,
        profile_id: @profile,
        per_page: 2

    assert_response :success
    submissions = assigns(:submissions)
    assert_equal 2, submissions.size
    assert submissions.include?(@submission)
    assert submissions.include?(@private_submission)

    get :index,
        profile_id: @profile,
        per_page: 2,
        page: 2

    assert_response :success
    submissions = assigns(:submissions)
    assert submissions.include?(@group_submission)
    assert submissions.include?(@collaboration_submission)
  end

  ###################################################################
  ## CREATE
  ###################################################################

 test "create" do
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create,
           profile_id: @profile,
           submission: {
             file: Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
           }
    end
    assert_response :created
    assert assigns(:submission)
  end

  test "create should apply previous submission in a series" do
    login_user
    set_profile
    assert_difference 'Submission.count', 1 do
      post :create,
           profile_id: @profile,
           submission: {
             submission_id: @submission.id
           }
    end
    submission = assigns(:submission)
    assert_equal submission.previous_submission, @submission
  end

  test "create should not create a new submission if given one in submission ids" do
    login_user
    set_profile
    new_submission = Submission.create(profile: @profile)

    assert_no_difference 'Submission.count' do
      post :create,
           profile_id: @profile,
           submission: {
             title: 'Cupcakes',
             description: 'I like cupcakes.',
             tags: ['dragon','cupcake'],
             replyable_id: @submission.id,
             replyable_type: 'Submission'
           },
           submission_ids: [new_submission.id]
    end
    assert_response :created
    new_submission.reload
    assert_equal 'Cupcakes', new_submission.title,
      "title was not set on submission"
    assert_equal 'I like cupcakes.', new_submission.description,
      "description was set on submission"
    assert_equal @submission, new_submission.replyable,
      "replyable was not carried over to the surviving submission"
    assert new_submission.tag_list.include?('cupcake'),
      "tag list was not updated on submission"
  end

  test "raw create with file data upload" do
    tmp_file_path = File.join(Rails.root, 'tmp', 'FLCL.jpg')
    FileUtils.rm(tmp_file_path) if File.exists?(tmp_file_path) # Cleanup if necessary
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'image/jpeg'
    @request.headers['Content-Disposition'] = 'inline; filename="FLCL.jpg"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create, profile_id: @profile
    end
    submission = assigns(:submission)
    submission.reload
    assert_equal 'FLCL.jpg', submission.file_file_name
    assert_equal 'image/jpeg', submission.file_content_type
  end

  test "raw create must save height and width" do
    tmp_file_path = File.join(Rails.root, 'tmp', 'FLCL.jpg')
    FileUtils.rm(tmp_file_path) if File.exists?(tmp_file_path) # Cleanup if necessary
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'image/jpeg'
    @request.headers['Content-Disposition'] = 'inline; filename="FLCL.jpg"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create, profile_id: @profile
    end
    submission = assigns(:submission)
    submission.reload
    assert_equal 1920, submission.width, "width was not set"
    assert_equal 1200, submission.height, "height was not set"
  end

  test "raw create with microsoft word docx file should succeed" do
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chapter1.docx')
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    @request.headers['Content-Disposition'] = 'inline; filename="Chapter1.docx"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create, profile_id: @profile
    end
    submission = assigns(:submission)
    submission.reload
  end

  test "raw create with open office odt file should succeed" do
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chapter1.odt')
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'application/vnd.oasis.opendocument.text'
    @request.headers['Content-Disposition'] = 'inline; filename="Chapter1.odt"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create, profile_id: @profile
    end
    submission = assigns(:submission)
    submission.reload
  end

  test "raw create with plain text file should succeed" do
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'Chapter1.txt')
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'text/plain'
    @request.headers['Content-Disposition'] = 'inline; filename="Chapter1.txt"'
    @request.env['RAW_POST_DATA'] = File.read(@file_path)
    login_user
    set_profile
    assert_difference 'Submission.count' do
      post :create, profile_id: @profile
    end
    submission = assigns(:submission)
    submission.reload
  end

  ###################################################################
  ## UPDATE
  ###################################################################

  test "update" do
    login_user
    set_profile
    @request.headers['Accept'] = 'application/json'
    assert_no_difference 'Submission.count' do
      patch :update,
            profile_id: @profile,
            id: @unpublished_submission,
            submission: {
              title: "A pudge of dragons.",
              description: "Even more dragons.",
              tag_list: "dragon,fat"
            }
    end
    assert_response :no_content
    @profile.reload
    assert_equal 'A pudge of dragons.', assigns(:submission).title
    assert_equal 'Even more dragons.', assigns(:submission).description
  end

  test "update should convert HTML body input to markdown" do
    login_user
    set_profile
    patch :update,
          profile_id: @profile,
          id: @unpublished_submission,
          submission: {
            title: 'A submission about dragons',
            description: '<p>Let me show you some <strong>toony</strong> dragons.</p>'
          }
    assert_response :no_content
    submission = assigns(:submission)
    assert !submission.description.match(/<[^>]*>/),
      "the submission description contains HTML"
  end

  test "update should not alter markdown body input" do
    login_user
    set_profile
    description_text = "Let me tell you about **toony** dragons."
    patch :update,
          profile_id: @profile,
          id: @unpublished_submission,
          submission: {
            title: 'A submission about dragons',
            description: description_text
          }
    assert_response :no_content
    submission = assigns(:submission)
    assert_equal description_text, submission.description,
      "the submission description markdown was changed when it shouldn't have"
  end

  test "update should add collaborators from tagged profiles in the description" do
    login_user
    set_profile
    tagged_profile = profiles(:dragon_profile_2)
    assert_no_difference 'Submission.count' do
      patch :update,
            profile_id: @profile,
            id: @unpublished_submission,
            submission: {
              title: "A donkey",
              description: "A picture of @#{tagged_profile.site_identifier}"
            }
    end
    @unpublished_submission.reload
    assert @unpublished_submission.collaborators.include?(tagged_profile),
      "tagged collaborator was not added"
  end

  test "update should add tags to submission tag list" do
    login_user
    set_profile
    assert_no_difference 'Submission.count' do
      patch :update,
            profile_id: @profile,
            id: @unpublished_submission,
            submission: {
              title: "A pudge of dragons.",
              description: "Even more dragons.",
              tags: ["dragon","fat"]
            }
    end
    @unpublished_submission.reload
    assert @unpublished_submission.tag_list.include?('dragon'), "tag was not included"
    assert @unpublished_submission.tag_list.include?('fat'), "tag was not included"
  end

  test "update should accept multiple filters" do
    login_user
    set_profile
    filter1 = filters(:dragon_friend_filter)
    filter2 = filters(:dragon_fatty_filter)
    patch :update,
          profile_id: @profile,
          id: @unpublished_submission,
          submission: {
            filter_ids: [filter1.id, filter2.id]
          }
    assert assigns(:submission).filters.include?(filter1),
      "a filter was not added to submission"
    assert assigns(:submission).filters.include?(filter2),
      "a filter was not added to submission"
  end

  test "update should accept blank tags" do
    login_user
    set_profile
    patch :update,
          profile_id: @profile,
          id: @unpublished_submission,
          title: 'A pudge of dragons.',
          description: 'Even more dragons.',
          tags: nil
    assert_response :no_content
    @unpublished_submission.reload
    assert_equal 'A pudge of dragons.', @unpublished_submission.title
  end

  test "update should not work for the submission of another profile" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    patch :update,
          profile_id: @profile,
          id: @submission,
          submission: {
            title: 'Changed it!'
          }
    @submission.reload
    assert_not_equal 'Changed it!', @submission.title
    assert_response :forbidden
  end

  test "update should not create a submission group if there is only one submission" do
    login_user
    set_profile
    assert_no_difference 'SubmissionGroup.count' do
      patch :update,
            profile_id: @profile,
            id: @unpublished_submission,
            submission: { title: 'A single image' },
            submission_ids: [@unpublished_submission.id]
    end
    @unpublished_submission.reload
    assert_nil @unpublished_submission.submission_group,
      "a single submission got put into a group"
  end

  # Thie reason we do this is because if an new submission exists (with replying, for example)
  # we need any new image used for it to take on all it's information, and get rid of the
  # "blank" submission.
  test "update should remove a submission with a blank file if the new params include a single image" do
    login_user
    set_profile
    edited_submission = Submission.create(profile: @profile, replyable: @submission)

    assert_difference 'Submission.count', -1 do
      patch :update,
            profile_id: @profile,
            id: edited_submission,
            submission: {
              title: 'Cupcakes',
              description: 'I like cupcakes.',
              tags: ['dragon','cupcake']
            },
            submission_ids: [@unpublished_submission.id]
    end
    assert_response :no_content
    @unpublished_submission.reload
    assert_equal 'Cupcakes', @unpublished_submission.title,
      "title was not set on submission"
    assert_equal 'I like cupcakes.', @unpublished_submission.description,
      "description was set on submission"
    assert_equal @submission, @unpublished_submission.replyable,
      "replyable was not carried over to the surviving submission"
    assert @unpublished_submission.tag_list.include?('cupcake'),
      "tag list was not updated on submission"
  end

  test "update should succeed on a submission group" do
    login_user
    set_profile
    submission = submissions(:dragon_group_submission_1)
    assert_no_difference 'Submission.count' do
      patch :update,
            profile_id: @profile,
            id: submission,
            submission: {
              title: 'A Pudge of Dragons',
              description: 'Dragons. How do they work?',
              tags: ['dragons','cupcakes','donuts']
            }
    end
    submission.reload
    assert_equal 'Dragons. How do they work?', submission.description,
      "description was not set"
    assert submission.tag_list.include?('dragons'),
      "tag list was not updated"
  end

  test "update should update tag list" do
    login_user
    set_profile
    assert_not @submission.tag_list.include?('herp')
    assert_not @submission.tag_list.include?('derp')
    patch :update,
          profile_id: @profile,
          id: @submission,
          submission: {
            tags: [
              'herp',
              'derp'
            ]
          }
    @submission.reload
    assert @submission.tag_list.include?('herp'),
      "tag was not added"
    assert @submission.tag_list.include?('derp'),
      "tag was not added"
  end

  ###################################################################
  ## UNPUBLISHED
  ###################################################################

  test "unpublished" do
    login_user
    set_profile
    get :unpublished, profile_id: @profile
    assert_response :success
    assert assigns(:submissions)
  end

  test "unpublished should not show published submissions" do
    login_user
    set_profile
    get :unpublished, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(@submission),
               "an published submission was shown"
    assert assigns(:submissions).include?(@unpublished_submission),
               "an unpublished submission was not shown"
  end

  test "unpublished should not show to other profiles" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    get :unpublished, profile_id: @profile
    assert_response :forbidden
  end

  test "unpublished should not show grouped submissions" do
    login_user
    set_profile
    submission = submissions(:dragon_unpublished_image_1)
    sg = SubmissionGroup.create(profile: @profile)
    sg.add_submission(submission)
    get :unpublished, profile_id: @profile
    assert_response :success
    assert_not assigns(:submissions).include?(submission),
               "a grouped submission was shown"
  end

  test "unpublished submissions by collaborators should not show up" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    set_profile(profile)
    @collaboration_submission.update_attribute(:published_at, nil)
    get :unpublished, profile_id: profile
    assert_not assigns(:submissions).include?(@collaboration_submission),
      "an unpublished submission by someone else showed up"
  end

  ###################################################################
  ## PUBLISH
  ###################################################################

  test "publish should publish a submission" do
    login_user
    set_profile
    patch :publish, profile_id: @profile, id: @unpublished_submission
    @unpublished_submission.reload
    assert @unpublished_submission.is_published?,
      "submission was not published"
    assert_response :no_content
  end

  test "publish should not work for the submission of another profile" do
    login_user(users(:lion))
    profile = profiles(:lion_profile_1)
    patch :publish, profile_id: @profile, id: @unpublished_submission
    @unpublished_submission.reload
    assert_not @unpublished_submission.is_published?
    assert_response :forbidden
  end

  ###################################################################
  ## DESTROY
  ###################################################################

  test "destroy" do
    login_user
    set_profile
    assert_difference 'Submission.count', -1 do
      delete :destroy, profile_id: @profile, id: @submission
    end
    assert_response :no_content
  end

  ###################################################################
  ## GROUP
  ###################################################################

  test "group should group submissions" do
    login_user
    set_profile
    @submission1 = submissions(:dragon_unpublished_image_1)
    @submission2 = submissions(:dragon_unpublished_image_2)

    assert_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission1.id,
             @submission2.id
           ]
    end

    assert_response :created
    submission = assigns(:submission)
    assert submission.is_a?(SubmissionGroup)
    assert submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@submission2)
  end

  test "group should allow grouping into existing submission group" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission_group.update_attribute(:published_at, nil)
    @grouped_submission = submissions(:dragon_group_image_1)
    @submission1 = submissions(:dragon_unpublished_image_1)

    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission_group.id,
             @submission1.id
           ]
    end

    assert_response :success
    submission = assigns(:submission)
    assert_equal @submission_group, submission
    assert submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@grouped_submission)
    assert_not submission.submissions.include?(@submission_group)
  end

  test "group should ungroup a submission if given a single id" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)
    @submission3 = submissions(:dragon_unpublished_image_2)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)
    @submission_group.add_submission(@submission3)

    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission1.id
           ]
    end

    assert_response :success
    submission = assigns(:submission)
    assert_equal @submission_group, submission
    assert_not submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@submission2)
    assert submission.submissions.include?(@submission3)
  end

  test "group should ungroup all if group is left with a single submission" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)

    assert_difference 'Submission.count', -1 do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission1.id
           ]
    end

    assert_response :no_content
    assert_nil @submission1.submission_group
    assert_not @submission2.submission_group
  end

  test "group should add to group if the first submissions is in a group" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)
    @submission3 = submissions(:dragon_unpublished_image_2)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)

    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission2.id,
             @submission3.id
           ]
    end

    assert_response :ok
    submission = assigns(:submission)
    assert_equal @submission_group, submission
    assert submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@submission2)
    assert submission.submissions.include?(@submission3)
  end

  test "group should create a new group if first submission is not in a group" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)
    @submission3 = submissions(:dragon_unpublished_image_2)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)

    post :group,
         profile_id: @profile,
         submission_ids: [
           @submission3.id,
           @submission2.id
         ]

    assert_response :created
    submission = assigns(:submission)
    assert_not_equal @submission_group, submission
    assert_not submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@submission2)
    assert submission.submissions.include?(@submission3)
  end

  test "group should remove orphaned submissions from their group" do
    login_user
    set_profile
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)
    @submission3 = submissions(:dragon_unpublished_image_2)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)

    # Now, when we add @submission2 to @submission3, @submission1 should be removed
    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission3.id,
             @submission2.id
           ]
    end

    assert_response :created
    submission = assigns(:submission)
    assert_not submission.submissions.include?(@submission1)
    assert submission.submissions.include?(@submission2)
    assert submission.submissions.include?(@submission3)
    assert_nil @submission1.submission_group
  end

  test "group should not group published submissions" do
    login_user
    set_profile
    @submission2 = submissions(:dragon_unpublished_image_2)

    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission.id,
             @submission2.id
           ]
    end

    assert_response :unprocessable_entity
    assert_nil @submission.submission_group
    assert_nil @submission2.submission_group
  end

  test "group should not allow grouping of unowned submissions" do
    login_user
    set_profile
    @submission = submissions(:lion_image_3)
    @submission.update_attribute(:published_at, nil)
    @submission2 = submissions(:dragon_unpublished_image_2)

    assert_no_difference 'Submission.count' do
      post :group,
           profile_id: @profile,
           submission_ids: [
             @submission.id,
             @submission2.id
           ]
    end

    assert_response :unprocessable_entity
    assert_nil @submission.submission_group
    assert_nil @submission2.submission_group
  end
end
