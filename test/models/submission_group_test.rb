require 'test_helper'

class SubmissionGroupTest < ActiveSupport::TestCase

  setup do
    @profile = profiles(:dragon_profile_1)
  end

  test "submission image should return a submission image class" do
    sg = SubmissionGroup.create(profile: @profile)
    image = submissions(:dragon_image_1)
    sg.add_submission(image)
    assert sg.submission_image.is_a?(SubmissionImage),
      "submission image was not a submission image"
  end

  test "submission groups should not be able to be added to submission groups" do
    submission_group_1 = SubmissionGroup.create(profile: @profile)
    submission_group_2 = SubmissionGroup.create(profile: @profile)
    submission_group_1.submission_group = submission_group_2
    assert_not submission_group_1.valid?,
      "submission group in another submission group should not be valid"
  end

  test "update attribute should not be able to add a submission group" do
    submission_group_1 = SubmissionGroup.create(profile: @profile)
    submission_group_2 = SubmissionGroup.create(profile: @profile)
    assert_raises SubmissionGroup::SubmissionGroupRecursionError do
      submission_group_1.update_attribute(:submission_group_id, submission_group_2.id)
    end
    submission_group_1.reload
    assert_not submission_group_1.submission_group,
      "a submission group got added to another submission group via update_attribute"
  end

  test "add and remove submission" do
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)
    @submission3 = submissions(:dragon_unpublished_image_2)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)
    @submission_group.add_submission(@submission3)

    assert @submission_group.submissions.include?(@submission1)
    assert @submission_group.submissions.include?(@submission2)
    assert @submission_group.submissions.include?(@submission3)

    @submission_group.remove_submission(@submission1)
    assert_not @submission_group.submissions.include?(@submission1)
    assert @submission_group.submissions.include?(@submission2)
    assert @submission_group.submissions.include?(@submission3)
  end

  test "remove submission should ungroup if only one submission left" do
    @submission_group = submissions(:dragon_group_submission_1)
    @submission1 = submissions(:dragon_group_image_1)
    @submission2 = submissions(:dragon_unpublished_image_1)

    @submission_group.update_attribute(:published_at, nil)
    @submission1.update_attribute(:published_at, nil)

    @submission_group.add_submission(@submission2)

    assert_difference 'SubmissionGroup.count', -1 do
      @submission_group.remove_submission(@submission1)
    end

    assert_nil @submission1.submission_group
    assert_nil @submission2.submission_group
  end
end
