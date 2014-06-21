require 'test_helper'

class FavoriteTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @submission = submissions(:dragon_image_1)
  end

  test "filtered submissions" do
    @profile = profiles(:dragon_profile_2)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    Favorite.create(profile: @profile, favable: @submission)
    Favorite.create(profile: @profile, favable: @filtered_submission)
    Favorite.create(profile: @profile, favable: @unpublished_submission)
    submissions = @profile.favorites.filtered_submissions.collect { |fave| fave.favable }
    assert submissions.include?(@submission),
      "a normal faved submission was not included"
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
    Favorite.create(profile: @profile, favable: @journal)
    Favorite.create(profile: @profile, favable: @filtered_journal)
    Favorite.create(profile: @profile, favable: @unpublished_journal)
    journals = @profile.favorites.filtered_journals.collect { |fave| fave.favable }
    assert journals.include?(@journal),
      "a normal faved journal was not included"
    assert_not journals.include?(@unpublished_journal),
      "an unpublished journal was included"
    assert_not journals.include?(@filtered_journal),
      "a filtered journal was included"
  end

  test "when a favorite is created, a tidbit for the favable's profile should be created" do
    assert_difference 'Tidbit.count' do
      @raccoon.fave(@submission)
    end
    assert @dragon.tidbits.last.targetable.is_a?(Favorite)
  end

  test "when a favorite is created, a tidbit for profiles following the faver should be created" do
    @lion.follow_profile(@raccoon)
    assert_difference 'Tidbit.count', 2 do
      @raccoon.fave(@submission)
    end
    assert @lion.tidbits.last.targetable.is_a?(Favorite)
  end

  # Profile A watches B, and B faves one of A's creations, only 1 tidbit should be created
  test "when a favorite is created on a creation by a watched profile, only one tidbit should be created" do
    @dragon.follow_profile(@raccoon)
    assert_difference 'Tidbit.count', 1 do
      @raccoon.fave(@submission)
    end
    assert @dragon.tidbits.last.targetable.is_a?(Favorite)
  end
 
  test "when a favorite is created for a filtered submission, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    @lion.fave(@filtered_submission)
    assert_nil @raccoon.tidbits.last
  end

  test "when a favorite is created for a filtered journal, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @filtered_journal = journals(:dragon_friend_journal_1)
    @filter.add_profile(@lion)
    @raccoon.follow_profile(@lion)
    @lion.fave(@filtered_journal)
    assert_nil @raccoon.tidbits.last
  end

  test "tidbits should not be created for faving streams" do
    assert_difference 'Tidbit.count', 1 do
      @raccoon.follow_profile(@dragon)
    end
  end
end