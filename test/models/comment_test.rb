require 'test_helper'

class CommentTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @submission = submissions(:dragon_image_1)
  end

  test "create without a commentable should fail" do
    assert_no_difference 'Comment.count' do
      comment = Comment.create(body: 'Body of the comment',
                               profile: @dragon)
      assert !comment.valid?
      assert comment.errors.keys.include?(:commentable_id)
      assert comment.errors.keys.include?(:commentable_type)
    end
  end

  test "create without body should fail" do
    assert_no_difference 'Comment.count' do
      comment = Comment.create(
                  commentable: @submission,
                  profile: @dragon)
      assert comment.errors.keys.include?(:body)
    end
  end

  test "create without profile should fail" do
    assert_no_difference 'Comment.count' do
      comment = Comment.create(
                  body: 'Body of the comment',
                  commentable: @submission)
      assert comment.errors.keys.include?(:profile_id)
    end
  end

  test "create body too long should fail" do
    assert_difference 'Comment.count' do
      Comment.create body: 'a' * 2000,
                     commentable: @submission,
                     profile: @dragon
    end
    assert_no_difference 'Comment.count' do
      comment = Comment.create body: "a" * 2001,
                               commentable: @submission,
                               profile: @dragon
      assert comment.errors.keys.include?(:body)
    end
  end

  test "comment creator should have access to modify comment" do
    comment = Comment.create(
                body: 'Body of the comment',
                commentable: @submission,
                profile: @lion)
    assert comment.profile_has_access?(@lion)
  end

  test "commentable owner should have access to delete comment" do
    comment = Comment.create(
                body: 'Body of the comment',
                commentable: @submission,
                profile: @lion)
    assert comment.profile_has_access?(@dragon)
  end

  test "non owner should not have access to modify comment" do
    comment = Comment.create(
                body: 'Body of the comment',
                commentable: @submission,
                profile: @dragon)
    assert !comment.profile_has_access?(@lion)
  end

  test "filtered submissions" do
    @profile = profiles(:dragon_profile_2)
    @submission = @submission
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    Comment.create(profile: @profile, body: 'Neat', commentable: @submission)
    Comment.create(profile: @profile, body: 'Neat', commentable: @filtered_submission)
    Comment.create(profile: @profile, body: 'Neat', commentable: @unpublished_submission)
    submissions = @profile.comments.filtered_submissions.collect { |comment| comment.commentable }
    assert submissions.include?(@submission),
      "a normal shared submission was not included"
    assert_not submissions.include?(@unpublished_submission),
      "an unpublished submission was included"
    assert_not submissions.include?(@filtered_submission),
      "a filtered submission was included"
  end

  test "filtered journals" do
    @profile = profiles(:dragon_profile_2)
    @journal = journals(:dragon_journal_1)
    @filtered_journal = journals(:dragon_friend_journal_1)
    @unpublished_journal = journals(:dragon_unpublished_journal_1)
    Comment.create(profile: @profile, body: 'Neat', commentable: @journal)
    Comment.create(profile: @profile, body: 'Neat', commentable: @filtered_journal)
    Comment.create(profile: @profile, body: 'Neat', commentable: @unpublished_journal)
    journals = @profile.comments.filtered_journals.collect { |comment| comment.commentable }
    assert journals.include?(@journal),
      "a normal shared journal was not included"
    assert_not journals.include?(@unpublished_journal),
      "an unpublished journal was included"
    assert_not journals.include?(@filtered_journal),
      "a filtered journal was included"
  end

  test "when a comment is created, a tidbit for the commentable's profile should be created" do
    assert_difference 'Tidbit.count' do
      @comment = Comment.create(
                  body: 'Body of the comment',
                  commentable: @submission,
                  profile: @lion)
    end
    assert_equal @comment, @submission.profile.tidbits.last.targetable
  end

  test "when a comment is created, a tidbit for profiles following the commenter should be created" do
    @raccoon.follow_profile(@lion)
    assert_difference 'Tidbit.count', 2 do
      @comment = Comment.create(
                  body: 'Body of the comment',
                  commentable: @submission,
                  profile: @lion)
    end
    assert_equal @comment, @raccoon.tidbits.last.targetable
  end

  # Profile A watches B, and B comments on one of A's creations, only 1 tidbit should be created
  test "when a share is created on a creation by a watched profile, only one tidbit should be created" do
    @dragon.follow_profile(@raccoon)
    assert_difference 'Tidbit.count', 1 do
      @comment = Comment.create(
                  body: 'Body of the comment',
                  commentable: @submission,
                  profile: @raccoon)
    end
    assert_equal @comment, @dragon.tidbits.last.targetable
  end

  test "when a comment is created for a filtered submission, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    @comment = Comment.create(
                body: 'Body of the comment',
                commentable: @filtered_submission,
                profile: @lion)
    assert_nil @raccoon.tidbits.last
  end

  test "when a comment is created for a filtered journal, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_journal = journals(:dragon_friend_journal_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    @comment = Comment.create(
                body: 'Body of the comment',
                commentable: @filtered_journal,
                profile: @lion)
    assert_nil @raccoon.tidbits.last
  end
end