require 'test_helper'

class CollaborationTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @owner = @dragon
    @collaborator = @lion
    @submission = submissions(:dragon_lion_collaboration_image_1)
  end

  test "cannot have duplicate profiles for the same submission" do
    assert_no_difference 'Collaboration.count' do
      Collaboration.create(profile: @collaborator, submission: @submission)
      assert_raises ActiveRecord::RecordInvalid do
        @submission.collaborators << @collaborator
      end
    end
  end

  test "notifications should be sent to collaborators after creation" do
    submission = submissions(:dragon_image_1)
    assert_difference 'Notification.count', 2 do
      submission.collaborators << @donkey
      submission.collaborators << @lion
    end
  end

  test "notifications should not be sent to the submission creator after creation" do
    assert_no_difference 'Notification.count' do
      submission = Submission.create(profile: @owner)
    end
  end

end
