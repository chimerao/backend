require 'test_helper'

class ShareTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @submission = submissions(:dragon_image_1)
  end

  test "filtered submissions" do
    @profile = @donkey
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    Share.create(profile: @profile, shareable: @submission)
    Share.create(profile: @profile, shareable: @filtered_submission)
    Share.create(profile: @profile, shareable: @unpublished_submission)
    submissions = @profile.shares.filtered_submissions.collect { |share| share.shareable }
    assert submissions.include?(@submission),
      "a normal shared submission was not included"
    assert_not submissions.include?(@unpublished_submission),
      "an unpublished submission was included"
    assert_not submissions.include?(@filtered_submission),
      "a filtered submission was included"
  end

  test "filtered journals" do
    @profile = @donkey
    @journal = journals(:dragon_journal_1)
    @filtered_journal = journals(:dragon_friend_journal_1)
    @unpublished_journal = journals(:dragon_unpublished_journal_1)
    Share.create(profile: @profile, shareable: @journal)
    Share.create(profile: @profile, shareable: @filtered_journal)
    Share.create(profile: @profile, shareable: @unpublished_journal)
    journals = @profile.shares.filtered_journals.collect { |share| share.shareable }
    assert journals.include?(@journal),
      "a normal shared journal was not included"
    assert_not journals.include?(@unpublished_journal),
      "an unpublished journal was included"
    assert_not journals.include?(@filtered_journal),
      "a filtered journal was included"
  end

  test "when a share is created, a tidbit for the sharable's profile should be created" do
    assert_difference 'Tidbit.count' do
      @share = Share.create(profile: @raccoon, shareable: @submission)
    end
    assert_equal @share, @dragon.tidbits.last.targetable
  end

  test "when a share is created, a tidbit for the profiles following the sharer should be created" do
    @lion.follow_profile(@raccoon)
    assert_difference 'Tidbit.count', 2 do
      @share = Share.create(profile: @raccoon, shareable: @submission)
    end
    assert_equal @share, @lion.tidbits.last.targetable
  end

  # Profile A watches B, and B shares one of A's creations, only 1 tidbit should be created
  test "when a share is created on a creation by a watched profile, only one tidbit should be created" do
    @dragon.follow_profile(@raccoon)
    assert_difference 'Tidbit.count', 1 do
      @share = Share.create(profile: @raccoon, shareable: @submission)
    end
    assert_equal @share, @dragon.tidbits.last.targetable
  end

  test "when a share is created for a filtered submission, profiles not part of the filter should not receive a thidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    Share.create(profile: @lion, shareable: @filtered_submission)
    assert_nil @raccoon.tidbits.last
  end

  test "when a share is created for a filtered journal, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_journal = journals(:dragon_friend_journal_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    Share.create(profile: @lion, shareable: @filtered_journal)
    assert_nil @raccoon.tidbits.last
  end

end
