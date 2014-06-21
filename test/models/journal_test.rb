require 'test_helper'

class JournalTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @journal = journals(:dragon_journal_1)
    @journal2 = journals(:dragon_unpublished_journal_1)
    @unpublished_journal = @journal2
  end

  test "created journal should have is_published set to false" do
    create_options = {
      profile: profiles(:dragon_profile_1),
      title: 'More dragon thoughts.',
      body: 'Herpy derp.'
    }
    assert_difference 'Journal.count' do
      @new_journal = Journal.create(create_options)
    end

    assert @new_journal.published_at.nil?, "published_at was set during create"
  end

  test "published scope" do
    journals = Journal.published
    assert journals.include?(journals(:dragon_journal_1))
    assert_not journals.include?(journals(:dragon_unpublished_journal_1))
  end

  test "unpublished scope" do
    journals = Journal.unpublished
    assert_not journals.include?(journals(:dragon_journal_1))
    assert journals.include?(journals(:dragon_unpublished_journal_1))
  end

  test "publish" do
    journal = journals(:dragon_unpublished_journal_1)
    assert_not journal.is_published?
    journal.publish!
    assert journal.is_published?
  end

  test "publish should not publish a journal that has no title" do
    journal = journals(:dragon_unpublished_journal_1)
    journal.update_attribute(:title, nil)
    journal.publish!
    assert_not journal.is_published?
    assert_not journal.errors[:title].blank?
  end

  test "is published should return false if not published" do
    journal = journals(:dragon_unpublished_journal_1)
    assert_equal false, journal.is_published?
  end

  test "can publish" do
    journal = journals(:dragon_unpublished_journal_1)
    assert journal.can_publish?,
      "journal was not publishable with a title"
    journal.update_attribute(:title, nil)
    assert_not journal.can_publish?,
      "journal was publishable without a title"
  end

  test "set url title when creating a journal" do
    profile = profiles(:dragon_profile_1)
    journal = Journal.new(profile: profile, body: 'Hey there.', title: 'A Fat Dragon')
    journal.save!
    assert_equal "a-fat-dragon", journal.url_title
  end

  test "set url title when saving a journal" do
    @journal.title = "New title for Dragon journal!"
    @journal.save!
    assert_equal "new-title-for-dragon-journal", @journal.url_title
  end

  test "actual profile pic should return proper profile pic" do
    assert_equal profile_pics(:dragon_profile_pic_2), @journal.actual_profile_pic
  end

  test "actual profile pic should return profile default pic if none is set on journal" do
    assert_equal @journal.profile.default_profile_pic, @journal2.actual_profile_pic
  end

  test "comments_count" do
    assert_equal 2, journals(:lion_journal_1).comments_count
  end

  test "favorites_count" do
    assert_equal 0, @journal.favorites_count
    Favorite.create(profile: @dragon, favable: @journal)
    assert_equal 1, @journal.favorites_count
    Favorite.create(profile: @donkey, favable: @journal)
    assert_equal 2, @journal.favorites_count
  end

  test "views_count" do
    assert_equal 0, @journal.views_count
    @journal.increment!(:views)
    assert_equal 1, @journal.views_count
  end

  test "shares_count" do
    assert_equal 0, @journal.shares_count
    Share.create(profile: @lion, shareable: @journal)
    assert_equal 1, @journal.shares_count
    Share.create(profile: @donkey, shareable: @journal)
    assert_equal 2, @journal.shares_count
  end


  test "is_filtered" do
    assert_not @journal.is_filtered?
    assert journals(:dragon_friend_journal_1).is_filtered?
  end

  test "filtered for profile should not exclude journals created by the profile" do
    journal = journals(:dragon_friend_journal_1)
    assert Journal.filtered_for_profile(profiles(:dragon_profile_1)).include?(journal),
           "owning profile did not have their journal displayed in collection"
  end

  test "filtered for profile should show journals to profiles in appropriate filters" do
    journal = journals(:dragon_friend_journal_1)
    filter = filters(:dragon_friend_filter)
    profile1 = @donkey
    profile2 = @lion
    filter.profiles << profile1
    profile1.reload
    assert Journal.filtered_for_profile(profile1).include?(journal)
    assert_not Journal.filtered_for_profile(profile2).include?(journal)
  end

  test "filtered for profile should not include journals that are in private filters" do
    journal = journals(:dragon_friend_journal_1)
    filter = filters(:dragon_friend_filter)
    profile1 = @donkey
    profile2 = @lion
    assert_not Journal.filtered_for_profile(profile1).include?(journal)
    assert_not Journal.filtered_for_profile(profile2).include?(journal)
  end

  test "filtered for profile should not return duplicate records" do
    profile = @donkey
    journals = profile.journals.filtered_for_profile(@dragon).published
    assert journals.include?(journals(:donkey_journal_1)),
      "profile's journal was not included"
    assert_equal 1, journals.size,
      "there were more journals than expected"
  end

  test "profile can view should disallow viewing of unpublished journal" do
    assert_not @unpublished_journal.profile_can_view?(@lion),
      "a profile saw an unpublished journal when they shouldn't have"
  end

  test "profile can view should allow viewing of unpublished journal for journal owner" do
    assert @unpublished_journal.profile_can_view?(@dragon),
      "a journal owner was unable to view their unpublished journal"
  end

  test "profile can view should disallow viewing of a private journal" do
    assert_not journals(:dragon_friend_journal_1).profile_can_view?(@lion)
  end

  test "profile can view should allow viewing of an owned journal" do
    assert journals(:dragon_friend_journal_1).profile_can_view?(@dragon)
  end

  test "profile can view should allow filtered profiles viewing of a journal" do
    journal = journals(:dragon_friend_journal_1)
    profile = @lion
    filter = filters(:dragon_friend_filter)
    assert_not journal.profile_can_view?(profile)
    filter.profiles << profile
    profile.reload
    assert journal.profile_can_view?(profile)
  end

  test "profile can view with nil profile should return false" do
    journal = journals(:dragon_friend_journal_1)
    assert_not journal.profile_can_view?(nil)
  end

  test "can be part of a series" do
    @journal3 = Journal.create(profile: profiles(:dragon_profile_1), title: 'Hey', body: 'Hi.')
    @journal3.previous_journal = @journal2
    @journal2.previous_journal = @journal
    @journal3.save!
    @journal2.save!
    @journal3.reload
    @journal2.reload
    @journal.reload
    assert_equal @journal3, @journal2.next_journal
    assert_equal @journal2, @journal.next_journal
    assert @journal.in_series?
    assert @journal2.in_series?
    assert @journal3.in_series?
  end

  test "in series must return true or false" do
    assert_equal false, @journal2.in_series?
    @journal2.previous_journal = @journal
    @journal2.save!
    @journal2.reload
    assert_equal true, @journal2.in_series?
  end

  test "next points to the next journal in a series or returns nil if none" do
    assert_not @journal.next_journal, "journal did not return nil for next"
    @journal.next_journal = @journal2
    @journal.save
    assert_equal @journal2, @journal.next_journal, "journal didn't get assigned to next"
  end

  test "previous points to the previous journal in a series or returns nil if none" do
    assert_not @journal2.previous_journal, "journal did not return nil for previous"
    @journal2.previous_journal = @journal
    @journal2.save
    assert_equal @journal, @journal2.previous_journal, "journal didn't get assigned to next"
  end

  test "can have submissions as replies" do
    reply_submission = submissions(:lion_image_1)
    reply_submission.replyable = @journal
    reply_submission.save!
    assert @journal.submission_replies.include?(reply_submission),
      "reply submission was not added to journal replies"
  end

  test "can have journals as replies" do
    reply_journal = journals(:lion_journal_1)
    reply_journal.replyable = @journal
    reply_journal.save!
    assert @journal.journal_replies.include?(reply_journal),
      "reply journal was not added to journal replies"
  end

  test "can be a response to a journal" do
    reply_journal = journals(:lion_journal_1)
    reply_journal.replyable = @journal
    reply_journal.save!
    assert_equal @journal, reply_journal.replyable,
      "journal did not get a replyable journal"
  end

  test "can be a response to a submission" do
    submission = submissions(:lion_image_1)
    @journal.replyable = submission
    @journal.save
    assert_equal submission, @journal.replyable,
      "journal did not get a replyable submission"
  end

  test "replies can return both submissions and journals" do
    reply_submission = submissions(:lion_image_1)
    reply_journal = journals(:lion_journal_1)
    reply_submission.replyable = @journal
    reply_submission.save!
    reply_journal.replyable = @journal
    reply_journal.save!
    assert @journal.replies.include?(reply_submission),
      "submission did not get included in replies"
    assert @journal.replies.include?(reply_journal),
      "journal did not get included in replies"
  end

  test "replies should not return unpublished submissions or journals" do
    reply_submission = submissions(:dragon_unpublished_image_1)
    reply_journal = journals(:dragon_unpublished_journal_1)
    reply_submission.replyable = @journal
    reply_submission.save!
    reply_journal.replyable = @journal
    reply_journal.save!
    assert_not @journal.replies.include?(reply_submission),
      "unpublished submission got included in replies"
    assert_not @journal.replies.include?(reply_journal),
      "unpublished journal got included in replies"
  end

  test "a journal cannot have a previous journal the profile does not own" do
    unowned_journal = journals(:donkey_journal_1)
    @journal.previous_journal = unowned_journal
    assert_not @journal.save,
      "unowned journal was set as previous"
    assert_not @journal.valid?
  end

  test "a journal cannot have a next journal the profile does not own" do
    unowned_journal = journals(:donkey_journal_1)
    assert_raises ActiveRecord::RecordNotSaved do
      @journal.next_journal = unowned_journal
    end
    @journal.reload
    assert_not_equal unowned_journal, @journal.next_journal
      "unowned journal was set as next"
  end

  test "a journal cannot have a previous journal that already has a next in a series" do
    @journal2.previous_journal = @journal
    @journal2.save!
    @journal.reload
    journal_params = { profile: @journal.profile, title: 'Next', body: 'Trying to fork.' }
    new_journal = Journal.new(journal_params)
    new_journal.previous_journal = @journal
    assert_not new_journal.save,
      "journal should not have been saved"
    assert_not new_journal.valid?,
      "journal should not be valid"
    assert_no_difference 'Journal.count' do
      Journal.create(journal_params.merge({ journal_id: @journal.id }))
    end
  end


  test "when a journal is published, a tidbit for the profiles following the creator should be created" do
    @lion.follow_profile(@raccoon)
    @journal = Journal.create(profile: @raccoon, body: 'Hey there.', title: 'A Fat Dragon')
    assert_difference 'Tidbit.count' do
      @journal.publish!
    end
    assert_equal @journal, @lion.tidbits.last.targetable
  end

  test "when a filtered journal is published, profiles part of the filter should receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @lion.follow_profile(@dragon)
    @filter.add_profile(@lion)
    @journal = @dragon.journals.create(title: 'A Journal', body: 'This is a journal.')
    @journal.publish!
    assert_equal @journal, @lion.tidbits.last.targetable
  end

  test "when a filtered journal is published, profiles not part of the filter should not receive a tidbit" do
    @filter = filters(:dragon_friend_filter)
    @lion.follow_profile(@dragon)
    @dragon.journals.create(title: 'A Journal', body: 'This is a journal.')
    @journal.publish!
    assert_nil @lion.tidbits.last
  end
end