require 'test_helper'

class SubmissionFolderTest < ActiveSupport::TestCase

  setup do
    @profile = profiles(:dragon_profile_1)
  end

  test "url name set before create" do
    folder = SubmissionFolder.create(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    assert_equal 'pantsless-dragons', folder.url_name
  end

  test "url name must be unique per profile" do
    SubmissionFolder.create(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    folder = SubmissionFolder.new(profile: profiles(:dragon_profile_1), name: 'Pantsless Dragons')
    assert_no_difference 'SubmissionFolder.count' do
      folder.save
    end
    assert_not folder.valid?
    folder = SubmissionFolder.new(profile: profiles(:dragon_profile_2), name: 'Pantsless Dragons')
    assert_difference 'SubmissionFolder.count' do
      folder.save
    end
  end

  test "permanent submission folders cannot be destroyed" do
    assert_no_difference 'SubmissionFolder.count' do
      submission_folders(:dragon_submission_folder).destroy
    end
  end

  test "add submission" do
    @submission = Submission.create(profile: @profile)
    @submission_folder = submission_folders(:dragon_dragons_folder)
    @submission_folder.add_submission(@submission)
    assert @submission_folder.submissions.include?(@submission),
      "submission was not added"
  end

  test "add submission should not add if the profile is not a collaborator" do
    @submission = submissions(:lion_image_1)
    @submission_folder = submission_folders(:dragon_dragons_folder)
    @submission_folder.add_submission(@submission)
    assert_not @submission_folder.submissions.include?(@submission),
      "an invalid submission was added"
  end

  test "add submission should not allow duplicates" do
    @submission = Submission.create(profile: @profile)
    @submission_folder = submission_folders(:dragon_dragons_folder)
    assert_equal 0, @submission_folder.submissions.count,
      "need to change initial conditions for this test due to fixture change"
    @submission_folder.add_submission(@submission)
    assert_equal 1, @submission_folder.submissions.count
    @submission_folder.add_submission(@submission)
    assert_equal 1, @submission_folder.submissions.count,
      "a duplicate submission was added"
  end

  test "add submission will give apply folder filters to submission" do
    @submission_folder = submission_folders(:dragon_dragons_folder)
    @filter = filters(:dragon_friend_filter)
    @submission_folder.filters << @filter
    @submission = submissions(:dragon_image_1)
    assert_not @submission.filters.include?(@filter)
    @submission_folder.add_submission(@submission)
    @submission.reload
    assert @submission.filters.include?(@filter),
      "filter was not applied to submission"
  end

  test "has submission" do
    @submission = Submission.create(profile: @profile)
    @submission_folder = submission_folders(:dragon_dragons_folder)
    @submission_folder.add_submission(@submission)
    assert @submission_folder.has_submission?(@submission)
  end
end
