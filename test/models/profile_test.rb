require 'test_helper'

class ProfileTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @profile = @dragon
  end

  test "site identifier" do
    assert_equal 'Dragon', @profile.site_identifier
    @profile.update_attribute(:site_identifier, 'FooDragon')
    assert_equal 'FooDragon', @profile.site_identifier
  end

  test "submission folder" do
    assert_equal submission_folders(:dragon_submission_folder), @profile.submission_folder
  end

  test "default submission folder must be created after profile create" do
    user = User.create(username: 'bunny', email: 'bunny@bunnies.com', password: 'bunnyfoo', password_confirmation: 'bunnyfoo')
    @profile = Profile.create(user: user, name: 'Bunny', site_identifier: 'Bunny')
    assert @profile.submission_folder,
      "submission folder was not created"
    assert @profile.submission_folder.is_permanent?
  end

  test "favorite folder" do
    assert_equal favorite_folders(:dragon_favorite_folder), @profile.favorite_folder
  end

  test "default favorite folder must be created after profile create" do
    user = User.create(username: 'bunny', email: 'bunny@bunnies.com', password: 'bunnyfoo', password_confirmation: 'bunnyfoo')
    @profile = Profile.create(user: user, name: 'Bunny', site_identifier: 'Bunny')
    assert @profile.favorite_folder,
      "favorite folder was not created"
    assert @profile.favorite_folder.is_permanent?
  end

  test "follow profile" do
    assert_difference 'Favorite.count', 5 do
      @profile.follow_profile(@lion)
    end
  end

  test "follow profile should add tidbit for followed profile" do
    assert_difference 'Tidbit.count' do
      @raccoon.follow_profile(@dragon)
    end
    assert_equal @raccoon, @dragon.tidbits.last.targetable
  end

  # A watches B. B follows C. A gets notification.
  # test "follow profile should add tidbits for followers of follower profile" do
  #   @raccoon.follow_profile(@dragon)
  #   @dragon.follow_profile(@lion)
  #   assert_equal @lion, @raccoon.tidbits.last.targetable
  # end

  test "unfollow profile" do
    @profile.follow_profile(@lion)
    assert_difference 'Favorite.count', -5 do
      @profile.unfollow_profile(@lion)
    end
  end

  test "unfollow profile should remove tidbit for followed profile" do
    @raccoon.follow_profile(@dragon)
    assert_difference 'Tidbit.count', -1 do
      @raccoon.unfollow_profile(@dragon)
    end
    assert_nil @dragon.tidbits.last
  end

  test "unfollow profile if they have no associated tidbit should not break" do
    @raccoon.unfollow_profile(@dragon)
  end

  test "following profile" do
    followed_profile = @lion
    assert_not @profile.following_profile?(followed_profile)
    @profile.follow_profile(followed_profile)
    assert @profile.following_profile?(followed_profile)
  end

  test "following profiles" do
    followed_profile = profiles(:lion_profile_1)
    assert_not @profile.following_profiles.include?(followed_profile)
    @profile.follow_profile(followed_profile)
    assert @profile.following_profiles.include?(followed_profile)
  end

  test "following profiles count" do
    assert_equal 0, @profile.following_profiles_count
    @profile.follow_profile(@lion)
    assert_equal 1, @profile.following_profiles_count
    @profile.follow_profile(@donkey)
    assert_equal 2, @profile.following_profiles_count
  end

  test "following stream" do
    @profile.follow_profile(@lion)
    assert @profile.following_stream?(streams(:lion_submissions_stream))
  end

  test "followed by profiles" do
    following_profile1 = @lion
    following_profile2 = @donkey

    assert_not @profile.followed_by_profiles.include?(following_profile1)
    assert_not @profile.followed_by_profiles.include?(following_profile2)

    following_profile1.follow_profile(@profile)

    assert @profile.followed_by_profiles.include?(following_profile1)
    assert_not @profile.followed_by_profiles.include?(following_profile2)

    following_profile2.follow_profile(@profile)

    assert @profile.followed_by_profiles.include?(following_profile1)
    assert @profile.followed_by_profiles.include?(following_profile2)
  end

  test "followed by profiles count" do
    assert_equal 0, @profile.followed_by_profiles_count
    @lion.follow_profile(@profile)
    assert_equal 1, @profile.followed_by_profiles_count
    @donkey.follow_profile(@profile)
    assert_equal 2, @profile.followed_by_profiles_count
  end

  test "collect profiles from string" do
    profile2 = @lion
    profiles = Profile.collect_profiles_from_string("This is for @#{profile2.site_identifier} and @#{@profile.site_identifier}")
    assert profiles.include?(@profile)
    assert profiles.include?(profile2)
  end

  test "approves submission should set the associated submission collaboration to approved" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    profile = @lion
    profile.approves!(submission)
    submission.reload
    assert submission.approved_collaborators.include?(profile),
      "profile was not added to approved collaborators"
  end

  test "approves submission should remove the associated notification" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    profile = @lion
    before_count = profile.notifications.count
    assert_difference 'Notification.count', -1 do
      profile.approves!(submission)
    end
    profile.reload
    assert_equal before_count - 1, profile.notifications.count,
      "notification was not removed from profile"
  end

  test "approves submission should allow another profile for the same user to approve" do
    submission = submissions(:lion_image_1)
    submission.add_collaborator(@dragon)
    @dragon.approves!(submission, for_profile: @donkey)
    submission.reload
    assert_not submission.approved_collaborators.include?(@dragon),
      "profile is still the collaborator when they should not be"
    assert submission.approved_collaborators.include?(@donkey),
      "new profile is not a collaborator but they should be"
  end

  test "approves submission for another profile should remove the associated notification" do
    submission = submissions(:lion_image_1)
    submission.add_collaborator(@dragon)
    before_count = @dragon.notifications.count
    @dragon.approves!(submission, for_profile: @donkey)
    @dragon.reload
    assert_equal before_count - 1, @dragon.notifications.count,
      "the associated notification was not destroyed"
  end

  test "approves submission should not allow a profile the user does not own to approve" do
    submission = submissions(:lion_image_1)
    submission.add_collaborator(@dragon)
    @dragon.approves!(submission, for_profile: @raccoon)
    submission.reload
    assert_not submission.approved_collaborators.include?(@raccoon),
      "unowned profile got set as a collaborator"
    assert submission.approved_collaborators.include?(@dragon),
      "original profile is no longer a collaborator, but they should be"
  end

  test "declines submission should remove the associated collaboration" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    profile = @lion
    assert_difference 'Collaboration.count', -1 do
      profile.declines!(submission)
    end
    submission.reload
    assert_not submission.collaborators.include?(profile),
      "profile was not removed from approved collaborators"
    assert_not submission.approved_collaborators.include?(profile),
      "profile was not removed from approved collaborators"
  end

  test "declines submission should remove the associated notification" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    profile = @lion
    before_count = profile.notifications.count
    assert_difference 'Notification.count', -1 do
      profile.declines!(submission)
    end
    profile.reload
    assert_equal before_count - 1, profile.notifications.count,
      "notification was not removed from profile"
  end

  test "claims submission should send a notification to owner" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    assert_difference 'Notification.count' do
      @lion.claims!(submission)
    end
    assert_equal 1, @profile.notifications.count
    assert_equal @lion, submission.owner,
      "claiming profile was not set as temporary owner"
  end

  test "relinquishes submission should change ownership of submission" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    @lion.claims!(submission)
    @profile.relinquishes!(submission)
    submission.reload
    assert_not_equal @profile, submission.profile,
      "ownership was not transferred"
    assert_equal @lion, submission.profile,
      "ownership was not transferred"
  end

  test "relinquishes should return nil if there is no profile requesting a claim" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    assert_nil @profile.relinquishes!(submission)
  end

  test "relinquishes should remove the associated notifiation" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    @lion.claims!(submission)
    assert_difference 'Notification.count', -1 do
      @profile.relinquishes!(submission)
    end
    assert_equal 0, @profile.notifications.count
  end

  test "relinquish should only work for a submissions parent profile" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    @lion.claims!(submission)
    @lion.relinquishes!(submission)
    assert_not_equal @lion, submission.profile,
      "ownership was transferred when it should not have been"
    assert_equal @profile, submission.profile,
      "ownership was transferred when it should not have been"
  end

  test "has faved submission" do
    @submission = submissions(:lion_image_1)
    @profile.favorites.create(favable: @submission)
    assert @profile.has_faved?(@submission),
      "submission should be faved"
  end

  test "has faved journal" do
    @journal = journals(:donkey_journal_1)
    @profile.favorites.create(favable: @journal)
    assert @profile.has_faved?(@journal),
      "journal should be faved"
  end

  test "has shared submission" do
    @submission = submissions(:lion_image_1)
    @profile.shares.create(shareable: @submission)
    assert @profile.has_shared?(@submission),
      "submission should be shared"
  end

  test "has shared journal" do
    @journal = journals(:donkey_journal_1)
    @profile.shares.create(shareable: @journal)
    assert @profile.has_shared?(@journal),
      "journal should be shared"
  end

  test "in filter" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    assert_not @profile.in_filter?(filter)
    filter.approve_profile(@profile)
    assert @profile.in_filter?(filter)
  end

  test "exposed profiles" do
    profile_ids = [@donkey.id]
    assert @profile.update_attributes(exposed_profiles: profile_ids)
    assert @profile.update_attributes(exposed_profiles: [])
    @profile.exposed_profiles = profile_ids
    assert @profile.save
    assert @profile.exposed_profiles.include?(@donkey.id)
  end

  test "exposed profiles cannot accept anything other than an id fixnum" do
    profile_ids = ["rar", @donkey.id]
    assert_not @profile.update_attributes(exposed_profiles: profile_ids)
    assert_not @profile.valid?
    @profile.reload
    assert_not @profile.exposed_profiles.include?('rar'),
      "something other than a Fixnum was put into exposed_profiles"
  end

  test "exposed profiles should not accept profiles that are not owned by the user" do
    profile_ids = [@donkey.id, @raccoon.id]
    assert_not @profile.update_attributes(exposed_profiles: profile_ids)
    assert_not @profile.valid?
    @profile.reload
    assert_not @profile.exposed_profiles.include?(@raccoon.id),
      "a profile id the user did not own was put into exposed_profiles"
  end

  test "exposed profiles should not contain self" do
    profile_ids = [@profile.id, @donkey.id]
    assert_not @profile.update_attributes(exposed_profiles: profile_ids)
    assert_not @profile.valid?
    @profile.reload
    assert_not @profile.exposed_profiles.include?(@profile.id),
      "self got inclued in exposed_profiles"
  end

  test "sent messages" do
    message = Message.create(sender: @profile, recipient: @raccoon, body: 'Hi')
    assert @profile.sent_messages.include?(message)
  end

  test "received messages" do
    message = Message.create(sender: @raccoon, recipient: @profile, body: 'Hi')
    assert @profile.received_messages.include?(message)
  end

  test "has banner image" do
    assert_not @profile.has_banner_image?
    @file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'FLCL.jpg')
    image = Rack::Test::UploadedFile.new(@file_path, 'image/jpeg')
    @profile.banner_image = image
    @profile.save!
    assert @profile.has_banner_image?
  end

  test "default profile pic" do
    assert @profile.default_profile_pic.is_a?(ProfilePic)
    assert_equal @profile.profile_pics.first, @profile.default_profile_pic
  end

  test "default profile pic should work for new records" do
    @profile = users(:dragon).profiles.create(name: 'Hippo', site_identifier: 'Hippo')
    assert @profile.default_profile_pic.is_a?(ProfilePic)
  end

  test "has profile pic" do
    assert @profile.has_profile_pic?
    assert_not profiles(:raccoon_profile_1).has_profile_pic?
  end

  test "destroy" do
    assert_difference 'Profile.count', -1 do
      @dragon.destroy
    end
  end
end
