require 'test_helper'

class StreamTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @profile = @dragon
  end

  test "permanent scope" do
    assert_equal 20, Stream.permanent.count
    assert_equal 5, @lion.streams.permanent.count
  end

  test "public scope" do
    streams = @profile.streams.are_public
    assert streams.include?(streams(:dragon_submissions_stream))
    assert streams.include?(streams(:dragon_public_dragon_stream))
    assert_not streams.include?(streams(:dragon_private_fatty_stream))
  end

  test "setting private should remove any favorites of the stream" do
    @stream = streams(:dragon_public_dragon_stream)
    following_profile = profiles(:lion_profile_1)
    following_profile.favorites.create(:favable => @stream)
    assert following_profile.favorites.streams.pluck(:favable_id).include?(@stream.id)
    assert_difference 'Favorite.count', -1 do
      @stream.update_attribute(:is_public, false)
    end
    assert_not following_profile.favorites.streams.include?(@stream)
  end

  test "permanent streams cannot be set private" do
    @stream = streams(:dragon_submissions_stream)
    assert @stream.is_public
    @stream.update_attribute(:is_public, false)
    assert @stream.is_public, "permanent Stream got set private"
  end

  test "include_submissions" do
    @stream = streams(:dragon_public_dragon_stream)
    assert @stream.include_submissions?
    assert_not @stream.include_journals?
  end

  test "include_journals" do
    @stream = Stream.new(name: 'Journal Test', rules: 'journals:all tags:dragons')
    assert @stream.include_journals?
    assert_not @stream.include_submissions?
  end

  test "limited_to_following" do
    @stream = Stream.new(name: 'Following Test', rules: 'profiles:followed tags:dragon')
    assert @stream.limited_to_following?
  end

  test "limited_to_profile" do
    assert streams(:dragon_submissions_stream).limited_to_profile?
    assert streams(:donkey_journals_stream).limited_to_profile?
    assert_not streams(:dragon_public_dragon_stream).limited_to_profile?
    assert_not streams(:dragon_private_fatty_stream).limited_to_profile?
  end

  test "deliver favorites should not return faved streams" do
    stream = streams(:dragon_favorites_stream)
    watched_profile = profiles(:lion_profile_1)
    @profile.follow_profile(watched_profile)
    favorites = stream.deliver
    assert !favorites.collect { |fave| fave.favable_type }.uniq.include?('Stream'),
           "Streams exist in returned favorites."
  end

  # A method for testing streams.
  #
  # options:
  # profile: A profile to create the stream for
  # must_include: Array of objects to check for
  # must_not_include: Array of objects to check against
  #
  def assert_stream(rules, options = {}, message)
    pass = true
    must_include = options.delete(:must_include)
    must_not_include = options.delete(:must_not_include)
    profile = options.delete(:profile)
    additional_message = ''

    stream = Stream.new(profile: profile, rules: rules)
    stream_results = stream.deliver(for_profile: profile).map { |item| 
      item.targetable
    }
    if must_include
      [must_include].flatten.each do |obj|
        if not stream_results.include?(obj)
          pass = false
          additional_message = "must_include failed on: #{obj.inspect}\n"
          break
        end
      end
    end
    if must_not_include
      [must_not_include].flatten.each do |obj|
        if stream_results.include?(obj)
          pass = false
          additional_message = "must_not_include failed on: #{obj.inspect}\n"
          break
        end
      end
    end
    assert pass, "#{additional_message}#{message}"
  end

  # Submission stream filtering tests

  def setup_submission_deliver_tests
    @regular_submission = submissions(:dragon_image_1)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    @filtered_submission = submissions(:dragon_friend_submission_1)    
    @profile = @raccoon
  end

  # Unpublished submissions

  test "deliver submissions should not return results with unpublished submissions" do
    setup_submission_deliver_tests
    stream = streams(:dragon_submissions_stream)
    assert_not stream.deliver(for_profile: @profile).include?(@unpublished_submission),
      "an unpublished submission was shown in a stream"
  end

  test "deliver all submissions should not return unpublished submissions" do
    setup_submission_deliver_tests
    assert_stream 'submissions:all', {
      profile: @profile,
      must_not_include: @unpublished_submission
    }, "an unpublished submission was shown in a stream"
  end

  test "deliver all tagged submissions should not return unpublished submissions" do
    setup_submission_deliver_tests
    @unpublished_submission.tag_list.add('dragon')
    @unpublished_submission.save!
    assert_stream 'submissions:all tags:dragon', {
      profile: @profile,
      must_not_include: [@unpublished_submission, @regular_submission]
    }, "an unpublished submission was shown in a stream"
  end

  test "deliver all submissions for profiles should not return unpublished submissions" do
    setup_submission_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'submissions:all profiles:followed', {
      profile: @profile,
      must_not_include: @unpublished_submission
    }, "an unpublished submission was shown in a stream"
  end

  test "deliver all tagged submissions for profiles should not return unpublished submissions" do
    setup_submission_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @unpublished_submission.tag_list.add('dragon')
    @unpublished_submission.save!
    assert_stream 'submissions:all profiles:followed tags:dragon', {
      profile: @profile,
      must_not_include: [@unpublished_submission, @regular_submission]
    }, "an unpublished submission was shown in a stream"
  end

  # Filtered submissions

  test "deliver submissions should not return filtered submissions" do
    setup_submission_deliver_tests
    stream = streams(:dragon_submissions_stream)
    assert_not stream.deliver(for_profile: @profile).include?(@filtered_submission),
      "a filtered submission was shown in a stream"
  end

  test "deliver all submissions should not return filtered submissions" do
    setup_submission_deliver_tests
    assert_stream 'submissions:all', {
      profile: @profile,
      must_not_include: @filtered_submission
    }, "a filtered submission was shown in a stream"
  end

  test "deliver all tagged submissions should not return filtered submissions" do
    setup_submission_deliver_tests
    @filtered_submission.tag_list.add('dragon')
    @filtered_submission.save!
    assert_stream 'submissions:all tags:dragon', {
      profile: @profile,
      must_not_include: [@filtered_submission, @regular_submission]
    }, "a filtered submission was shown in a stream"
  end

  test "deliver all submissions for profiles should not return filtered submissions" do
    setup_submission_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'submissions:all profiles:followed', {
      profile: @profile,
      must_not_include: @filtered_submission
    }, "a filtered submission was shown in a stream"
  end

  test "deliver all tagged submissions for profiles should not return filtered submissions" do
    setup_submission_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @filtered_submission.tag_list.add('dragon')
    @filtered_submission.save!
    assert_stream 'submissions:all profiles:followed tags:dragon', {
      profile: @profile,
      must_not_include: [@filtered_submission, @regular_submission]
    }, "a filtered submission was shown in a stream"
  end

  # All the following are for when a profile views a submission stream from another profile

  def setup_submission_filter_tests
    setup_submission_deliver_tests
    @stream = streams(:dragon_submissions_stream)
    @filter = filters(:dragon_friend_filter)
    @filter.profiles << @profile
    @filter.approve_profile(@profile)    
  end

  test "deliver default submission stream should return filtered submissions for appropriate profiles" do
    setup_submission_filter_tests
    assert @stream.deliver(for_profile: @profile).map { |item| item.targetable }.include?(@filtered_submission),
      "a filtered submission was not shown to someone in the filter"
  end

  test "deliver all submissions should return filtered submissions for appropriate profiles" do
    setup_submission_filter_tests
    assert_stream 'submissions:all', {
      profile: @profile,
      must_include: @filtered_submission
    }, "a filtered submission was not shown to approprite profile"
  end

  test "deliver all tagged submissions should return filtered submissions for appropriate profiles" do
    setup_submission_filter_tests
    @filtered_submission.tag_list.add('dragon')
    @filtered_submission.save!
    assert_stream 'submissions:all tags:dragon', {
      profile: @profile,
      must_include: @filtered_submission,
      must_not_include: @regular_submission
    }, "a filtered submission was not shown to approprite profile"
  end

  test "deliver all submissions for profiles should return filtered submissions for appropriate profiles" do
    setup_submission_filter_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'submissions:all profiles:followed', {
      profile: @profile,
      must_include: @filtered_submission
    }, "a filtered submission was not shown to approprite profile"
  end

  test "deliver all tagged submissions for profiles should return filtered submissions for appropriate profiles" do
    setup_submission_filter_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @filtered_submission.tag_list.add('dragon')
    @filtered_submission.save!
    assert_stream 'submissions:all profiles:followed tags:dragon', {
      profile: @profile,
      must_include: @filtered_submission,
      must_not_include: @regular_submission
    }, "a filtered submission was not shown to approprite profile"
  end

  # Journal stream filtering tests

  def setup_journal_deliver_tests
    @regular_journal = journals(:dragon_journal_1)
    @unpublished_journal = journals(:dragon_unpublished_journal_1)
    @filtered_journal = journals(:dragon_friend_journal_1)    
    @profile = profiles(:raccoon_profile_1)
  end

  # Unpublished journals

  test "deliver journals should not return unpublished journals" do
    setup_journal_deliver_tests
    stream = streams(:dragon_journals_stream)
    assert_not stream.deliver(for_profile: @profile).include?(@unpublished_journal),
      "an unpublished journal was shown in a stream"
  end

  test "deliver all journals should not return unpublished journals" do
    setup_journal_deliver_tests
    assert_stream 'journals:all', {
      profile: @profile,
      must_not_include: @unpublished_journal
    }, "an unpublished journal was shown in a stream"
  end

  test "deliver all tagged journals should not return unpublished journals" do
    setup_journal_deliver_tests
    @unpublished_journal.tag_list.add('dragon')
    @unpublished_journal.save
    assert_stream 'journals:all tags:dragon', {
      profile: @profile,
      must_not_include: [@unpublished_journal, @regular_journal]
    }, "an unpublished journal was shown in a stream"
  end

  test "deliver all journals for profiles should not return unpublished journals" do
    setup_journal_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'journals:all profiles:followed', {
      profile: @profile,
      must_not_include: @unpublished_journal
    }, "an unpublished journal was shown in a stream"
  end

  test "deliver all tagged journals for profiles should not return unpublished journals" do
    setup_journal_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @unpublished_journal.tag_list.add('dragon')
    @unpublished_journal.save
    assert_stream 'journals:all profiles:followed tags:dragon', {
      profile: @profile,
      must_not_include: [@unpublished_journal, @regular_journal]
    }, "an unpublished journal was shown in a stream"
  end

  # Filtered journals

  test "deliver journals should not return filtered journals" do
    setup_journal_deliver_tests
    stream = streams(:dragon_journals_stream)
    assert_not stream.deliver(for_profile: @profile).include?(@filtered_journal),
      "a filtered journal was shown in a stream"
  end

  test "deliver all journals should not return filtered journals" do
    setup_journal_deliver_tests
    assert_stream 'journals:all', {
      profile: @profile,
      must_not_include: @filtered_journal
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all tagged journals should not return filtered journals" do
    setup_journal_deliver_tests
    @filtered_journal.tag_list.add('dragon')
    @filtered_journal.save
    assert_stream 'journals:all tags:dragon', {
      profile: @profile,
      must_not_include: [@filtered_journal, @regular_journal]
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all journals for profiles should not return filtered journals" do
    setup_journal_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'journals:all profiles:followed', {
      profile: @profile,
      must_not_include: @filtered_journal
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all tagged journals for profiles should not return filtered journals" do
    setup_journal_deliver_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @filtered_journal.tag_list.add('dragon')
    @filtered_journal.save
    assert_stream 'journals:all profiles:followed tags:dragon', {
      profile: @profile,
      must_not_include: [@filtered_journal, @regular_journal]
    }, "a filtered journal was shown in a stream"
  end

  # All the following are for when a profile views a journal stream from another profile

  def setup_journal_filter_tests
    setup_journal_deliver_tests
    @stream = streams(:dragon_journals_stream)
    @filter = filters(:dragon_friend_filter)
    @filter.profiles << @profile
    @filter.approve_profile(@profile)
  end

  test "deliver default journal stream should return filtered journals for appropriate profiles" do
    setup_journal_filter_tests
    assert @stream.deliver(for_profile: @profile).map { |item| item.targetable }.include?(@filtered_journal),
      "a filtered submission was not shown to someone in the filter"
  end

  test "deliver all journals should return filtered journals for appropriate profiles" do
    setup_journal_filter_tests
    assert_stream 'journals:all', {
      profile: @profile,
      must_include: @filtered_journal
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all tagged journals should return filtered journals for appropriate profiles" do
    setup_journal_filter_tests
    @filtered_journal.tag_list.add('dragon')
    @filtered_journal.save
    assert_stream 'journals:all tags:dragon', {
      profile: @profile,
      must_include: @filtered_journal,
      must_not_include: @regular_journal
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all journals for profiles should return filtered journals for appropriate profiles" do
    setup_journal_filter_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    assert_stream 'journals:all profiles:followed', {
      profile: @profile,
      must_include: @filtered_journal
    }, "a filtered journal was shown in a stream"
  end

  test "deliver all tagged journals for profiles should return filtered journals for appropriate profiles" do
    setup_journal_filter_tests
    @profile.follow_profile(profiles(:dragon_profile_1))
    @filtered_journal.tag_list.add('dragon')
    @filtered_journal.save
    assert_stream 'journals:all profiles:followed tags:dragon', {
      profile: @profile,
      must_include: @filtered_journal,
      must_not_include: @regular_journal
    }, "a filtered journal was shown in a stream"
  end

  # Favorites streams

  test "deliver favorites should return results with unfiltered published submissions" do
    stream = streams(:donkey_favorites_stream)
    @submission = submissions(:dragon_image_1)
    Favorite.create(profile: profiles(:dragon_profile_2), favable: @submission)
    favorites = stream.deliver.map { |item| item.targetable }
    assert favorites.collect { |fave| fave.favable_id }.include?(@submission.id),
      "a submission that was supposed to be included was not"
  end

  test "deliver favorites should not return results with unpublished submissions" do
    stream = streams(:donkey_favorites_stream)
    @unpublished_submission = submissions(:dragon_friend_submission_1)
    Favorite.create(profile: profiles(:dragon_profile_2), favable: @unpublished_submission)
    favorites = stream.deliver.map { |item| item.targetable }
    assert_not favorites.collect { |fave| fave.favable_id }.include?(@unpublished_submission.id),
      "an unpublished submission was shown in a fave on a stream"
  end

  test "deliver favorites should not return results with filtered submissions" do
    stream = streams(:donkey_favorites_stream)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    Favorite.create(profile: profiles(:dragon_profile_2), favable: @filtered_submission)
    favorites = stream.deliver.map { |item| item.targetable }
    assert_not favorites.collect { |fave| fave.favable_id }.include?(@filtered_submission.id),
      "a filtered submission was shown in a fave on a stream"
  end

  # Comments streams

  test "deliver comments should return results with unfiltered published submissions" do
    stream = streams(:donkey_comments_stream)
    @submission = submissions(:dragon_image_1)
    Comment.create(profile: profiles(:dragon_profile_2), commentable: @submission, body: 'Neat')
    comments = stream.deliver.map { |item| item.targetable }
    assert comments.collect { |comment| comment.commentable_id }.include?(@submission.id),
      "a submission that was supposed to be included was not"
  end

  test "deliver comments should not return results with unpublished submissions" do
    stream = streams(:donkey_comments_stream)
    @unpublished_submission = submissions(:dragon_friend_submission_1)
    Comment.create(profile: profiles(:dragon_profile_2), commentable: @unpublished_submission, body: 'Neat')
    comments = stream.deliver.map { |item| item.targetable }
    assert_not comments.collect { |comment| comment.commentable_id }.include?(@unpublished_submission.id),
      "an unpublished submission was shown in a comment on a stream"
  end

  test "deliver comments should not return results with filtered submissions" do
    stream = streams(:donkey_comments_stream)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    Comment.create(profile: profiles(:dragon_profile_2), commentable: @filtered_submission, body: 'Neat')
    comments = stream.deliver.map { |item| item.targetable }
    assert_not comments.collect { |comment| comment.commentable_id }.include?(@filtered_submission.id),
      "a filtered submission was shown in a comment on a stream"
  end


  # Shares streams

  test "deliver shares should return results with unfiltered published submissions" do
    stream = streams(:donkey_shares_stream)
    @submission = submissions(:dragon_image_1)
    Share.create(profile: profiles(:dragon_profile_2), shareable: @submission)
    shares = stream.deliver.map { |item| item.targetable }
    assert shares.collect { |share| share.shareable_id }.include?(@submission.id),
      "a submission that was supposed to be included was not"
  end

  test "deliver shares should not return results with unpublished submissions" do
    stream = streams(:donkey_shares_stream)
    @unpublished_submission = submissions(:dragon_friend_submission_1)
    Share.create(profile: profiles(:dragon_profile_2), shareable: @unpublished_submission)
    shares = stream.deliver.map { |item| item.targetable }
    assert_not shares.collect { |share| share.shareable_id }.include?(@unpublished_submission.id),
      "an unpublished submission was shown in a share on a stream"
  end

  test "deliver shares should not return results with filtered submissions" do
    stream = streams(:donkey_shares_stream)
    @filtered_submission = submissions(:dragon_friend_submission_1)
    Share.create(profile: profiles(:dragon_profile_2), shareable: @filtered_submission)
    shares = stream.deliver.map { |item| item.targetable }
    assert_not shares.collect { |share| share.shareable_id }.include?(@filtered_submission.id),
      "a filtered submission was shown in a share on a stream"
  end

  # Parse tests

  test "submissions from everyone a profile follows" do
    stream = Stream.new(profile: @profile, rules: 'submissions:all profiles:followed')
    submission1 = submissions(:dragon_image_1)
    submission2 = submissions(:lion_image_1)

    items = stream.deliver.map { |item| item.targetable }
    assert_not items.include?(submission1)
    assert_not items.include?(submission2)

    @profile.follow_profile(@dragon)

    items = stream.deliver.map { |item| item.targetable }
    assert items.include?(submission1)
    assert_not items.include?(submission2)

    @profile.follow_profile(@lion)

    items = stream.deliver.map { |item| item.targetable }
    assert items.include?(submission1)
    assert items.include?(submission2)
  end

  test "journals from everyone a profile follows" do
    stream = Stream.new(profile: @profile, rules: 'journals:all profiles:followed')
    journal1 = journals(:donkey_journal_1)
    journal2 = journals(:lion_journal_1)

    items = stream.deliver.map { |item| item.targetable }
    assert_not items.include?(journal1)
    assert_not items.include?(journal2)

    @profile.follow_profile(@donkey)

    items = stream.deliver.map { |item| item.targetable }
    assert items.include?(journal1)
    assert_not items.include?(journal2)

    @profile.follow_profile(@lion)

    items = stream.deliver.map { |item| item.targetable }
    assert items.include?(journal1)
    assert items.include?(journal2)
  end

  test "all submissions posted tagged with dragon and nsfw" do
    stream = Stream.new(profile: @profile, rules: 'submissions:all tags:dragon,nsfw')
    image1 = submissions(:dragon_image_1)
    image2 = submissions(:lion_image_2)
    image1.tag_list.add('dragon')
    image1.save
    image2.tag_list.add('dragon', 'nsfw')
    image2.save

    items = stream.deliver.map { |item| item.targetable }

    assert_not items.include?(image1), 'dragon_image_1 should not be included'
    assert items.include?(image2), 'lion_image_2 should be included'
  end

  test "all journals tagged with convention" do
    stream = Stream.new(profile: @profile, rules: 'journals:all tags:convention')
    journal1 = journals(:lion_journal_1)
    journal1.tag_list.add('convention')
    journal1.save
    journal2 = journals(:donkey_journal_1)
    journal2.tag_list.add('convention', 'costume')
    journal2.save

    items = stream.deliver.map { |item| item.targetable }

    assert_not items.include?(journals(:dragon_journal_1))
    assert items.include?(journal1)
    assert items.include?(journal2)
  end

  test "all site activity tagged with ourfunnyinjoke" do
    stream = Stream.new(profile: @profile, rules: 'tags:ourfunnyinjoke')
    journal = journals(:donkey_journal_1)
    journal.tag_list.add('ourfunnyinjoke')
    journal.save
    submission = submissions(:lion_image_1)
    submission.tag_list.add('ourfunnyinjoke')
    submission.save

    items = stream.deliver.map { |item| item.targetable }

    assert items.include?(journal), "donkey_journal_1 should be included"
    assert items.include?(submission), "lion_image_1 should be included"
    assert_not items.include?(journals(:dragon_journal_1)),
      "dragon_journal_1 should not be included"
    assert_not items.include?(submissions(:dragon_image_1)),
      "dragon_image_1 should not be included"
  end

  test "all site activity except favorites and comments posted by list of friends" do
    stream = Stream.new(profile: @profile, rules: 'profiles:tagged:friend favorites:none comments:none')
    @profile.follow_profile(@lion)
    @profile.tag(@lion, with: 'friend', on: :relations)

    favorite = @lion.favorites.create(favable: submissions(:dragon_image_1))
    comment = @lion.comments.create(commentable: submissions(:dragon_image_1), body: 'Neat')

    items = stream.deliver.map { |item| item.targetable }

    assert items.include?(submissions(:lion_image_2))
    assert_not items.include?(favorite)
    assert_not items.include?(comment)
  end

end
