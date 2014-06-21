require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @profile = @lion
    @submission = submissions(:lion_image_1)
    @submission2 = submissions(:lion_image_2)
    @submission3 = submissions(:lion_image_3)
  end

  test "created submission should have is_published set to false" do
    create_options = {
      profile: @profile,
      title: 'FLCL',
      description: 'A great series'
    }
    assert_difference 'Submission.count' do
      @new_submission = Submission.create(create_options)
    end

    assert @new_submission.published_at.nil?, "published_at was set during create"
  end

  test "created submission should have the creating profile as a collaborator" do
    create_options = {
      profile: @profile,
      title: 'FLCL',
      description: 'A great series'
    }
    assert_difference 'Submission.count' do
      @new_submission = Submission.create(create_options)
    end

    assert @new_submission.collaborators.include?(@profile),
      "creating profile was not added as a collaborator"
  end

  test "published scope" do
    submissions = Submission.published
    assert submissions.include?(submissions(:dragon_image_1))
    assert_not submissions.include?(submissions(:dragon_unpublished_image_1))
  end

  test "unpublished scope" do
    submissions = Submission.unpublished
    assert_not submissions.include?(submissions(:dragon_image_1))
    assert submissions.include?(submissions(:dragon_unpublished_image_1))
  end

  test "publish" do
    submission = submissions(:dragon_unpublished_image_1)
    assert_not submission.is_published?
    submission.publish!
    assert submission.is_published?
  end

  test "publish should not publish a submission that has no title" do
    submission = submissions(:dragon_unpublished_image_1)
    submission.update_attribute(:title, nil)
    submission.publish!
    assert_not submission.is_published?
    assert_not submission.errors[:title].blank?
  end

  test "can publish" do
    submission = submissions(:dragon_unpublished_image_1)
    assert submission.can_publish?,
      "submission was publishable without a title"
    submission.update_attribute(:title, nil)
    assert_not submission.can_publish?,
      "submission was publishable without a title"
  end

  test "cannot publish a submission that is part of a submission group" do
    submission_group = SubmissionGroup.create(profile: @profile)
    submission1 = submissions(:dragon_unpublished_image_1)
    submission2 = submissions(:dragon_unpublished_image_2)
    submission_group.add_submission(submission1)
    submission_group.add_submission(submission2)
    assert_not submission1.publish!,
      "an individual submission in a submission group got published"
  end

  test "cannot publish a submission that is already published" do
    assert_not @submission.publish!,
      "a published submission got re-published"
  end

  test "set url title when saving a submission" do
    @submission.title = "New title for Lion image!"
    @submission.save
    assert_equal "new-title-for-lion-image", @submission.url_title
  end

  test "add collaborator" do
    collaborator = profiles(:dragon_profile_1)
    assert_not @submission.collaborators.include?(collaborator)
    assert_difference 'Collaboration.count' do
      @submission.add_collaborator(collaborator)
    end
    assert @submission.collaborators.include?(collaborator),
      "collaborator was not added"
  end

  test "add collaborator cannot add duplicate collaborators" do
    collaborator = profiles(:dragon_profile_1)
    @submission.add_collaborator(collaborator)
    assert_no_difference 'Collaboration.count' do
      @submission.add_collaborator(collaborator)
    end
  end

  test "remove collaborator" do
    collaborator = profiles(:dragon_profile_1)
    @submission.add_collaborator(collaborator)
    assert @submission.collaborators.include?(collaborator)
    assert_difference 'Collaboration.count', -1 do
      @submission.remove_collaborator(collaborator)
    end
    assert_not @submission.collaborators.include?(collaborator),
      "collaborator was not removed"
  end

  # There must always be at least one.
  test "remove collaborator cannot leave a submission without any collaborators" do
    assert_no_difference 'Collaboration.count' do
      @submission.remove_collaborator(@profile)
    end
    assert @submission.collaborators.include?(@profile),
      "a submission was left without collaborators"
  end

  test "add collaborators from description" do
    collaborator = profiles(:dragon_profile_1)
    assert_not @submission.collaborators.include?(collaborator)
    @submission.description = "A picture for @#{collaborator.site_identifier}."
    assert_difference 'Collaboration.count' do
      @submission.add_collaborators_from_description
    end
    assert @submission.collaborators.include?(collaborator),
      "collaborators were not added from description"
  end

  test "comments_count" do
    assert_equal 2, @submission.comments_count
  end

  test "favorites_count" do
    assert_equal 0, @submission.favorites_count
    Favorite.create(profile: profiles(:dragon_profile_1), favable: @submission)
    assert_equal 1, @submission.favorites_count
    Favorite.create(profile: profiles(:dragon_profile_2), favable: @submission)
    assert_equal 2, @submission.favorites_count
  end

  test "views_count" do
    assert_equal 0, @submission.views_count
    @submission.increment!(:views)
    assert_equal 1, @submission.views_count
  end

  test "shares_count" do
    assert_equal 0, @submission.shares_count
    Share.create(profile: profiles(:dragon_profile_1), shareable: @submission)
    assert_equal 1, @submission.shares_count
    Share.create(profile: profiles(:dragon_profile_2), shareable: @submission)
    assert_equal 2, @submission.shares_count
  end

  test "is adult" do
    assert_equal false, @submission.is_adult?
    @submission.tag_list.add('adult')
    assert_equal true, @submission.is_adult?
  end

  test "is_filtered" do
    assert_not @submission.is_filtered?
    assert submissions(:dragon_friend_submission_1).is_filtered?
  end

  # profile can see own work
  test "filtered for profile should not exclude submissions created by the profile" do
    submission1 = submissions(:dragon_image_1)
    submission2 = submissions(:dragon_friend_submission_1)
    assert Submission.filtered_for_profile(profiles(:dragon_profile_1)).include?(submission1),
      "owning profile did not have their submission displayed in collection"
    assert Submission.filtered_for_profile(profiles(:dragon_profile_1)).include?(submission2),
      "owning profile did not have their submission displayed in collection"
  end

  # profiles should see filtered work if they're in filter
  test "filtered for profile should show submissions to profiles in appropriate filters" do
    submission = submissions(:dragon_friend_submission_1)
    filter = filters(:dragon_friend_filter)
    profile1 = profiles(:dragon_profile_2)
    profile2 = profiles(:lion_profile_1)
    filter.filter_profiles.create(profile: profile1, is_approved: true)
    profile1.reload
    assert Submission.filtered_for_profile(profile1).include?(submission),
      "submission did not get included for profile in filter"
    assert_not Submission.filtered_for_profile(profile2).include?(submission),
      "submission got included for profile not in filter"
  end

  # profiles should not see filtered work if they're not in the filter
  test "filtered for profile should not include submissions that are in private filters" do
    submission = submissions(:dragon_friend_submission_1)
    filter = filters(:dragon_friend_filter)
    profile1 = profiles(:dragon_profile_2)
    profile2 = profiles(:lion_profile_1)
    assert_not Submission.filtered_for_profile(profile1).include?(submission),
      "a profile saw a private submission in a collection they shouldn't have"
    assert_not Submission.filtered_for_profile(profile2).include?(submission),
      "a profile saw a private submission in a collection they shouldn't have"
  end

  # profiles should not see art for filters they are not approved in yet
  test "filtered for profile should not show unapproved filter submissions" do
    submission = submissions(:dragon_friend_submission_1)
    filter = filters(:dragon_friend_filter)
    profile1 = profiles(:dragon_profile_2)
    filter.filter_profiles.create(profile: profile1)
    profile1.reload
    assert_not Submission.filtered_for_profile(profile1).include?(submission),
      "submission was included in filtered results when it should not have"
  end

  test "filtered for profile for another profile should not show unapproved filter submissions" do
    submission = submissions(:dragon_friend_submission_1)
    filter = filters(:dragon_friend_filter)
    profile1 = profiles(:dragon_profile_2)
    filter.filter_profiles.create(profile: profile1)
    profile1.reload
    assert_not Submission.filtered_for_profile(profile1, for_profile: filter.profile).include?(submission),
      "submission was included in filtered results when it should not have"
  end

  # viewing a creators page should show all their own work, including collaborations
  test "filtered for profile for a creator should include submissions that are collaborated on" do
    submission = submissions(:dragon_image_1)
    collaborator = profiles(:lion_profile_1)
    creator = profiles(:dragon_profile_1)
    submission.add_collaborator(collaborator)
    assert Submission.filtered_for_profile(collaborator, :for_profile => creator).include?(submission),
      "collaborator submission did not show up on the creator page to the collaborator"
    assert Submission.filtered_for_profile(creator, :for_profile => creator).include?(submission),
      "collaborator submission did not show up on the creator page to the creator"
  end

  # viewing a collaborators page should show all work that they collaborated on
  test "filtered for profile for a collaborator should include submissions that are collaborated on" do
    submission = submissions(:dragon_image_1)
    collaborator = profiles(:lion_profile_1)
    creator = profiles(:dragon_profile_1)
    submission.add_collaborator(collaborator)
    collaborator.approves!(submission)
    assert Submission.filtered_for_profile(collaborator, :for_profile => collaborator).include?(submission),
      "collaborator submission did not show up on the collaborator page to the collaborator"
    assert Submission.filtered_for_profile(creator, :for_profile => collaborator).include?(submission),
      "collaborator submission did not show up on the collaborator page to the creator"
  end

  # viewing a collaborators page should not show work that is not approved
  test "filtered for profile for a collaborator should not include unapproved submissions" do
    @collaboration_submission = submissions(:dragon_lion_collaboration_image_1)
    collaborator = profiles(:lion_profile_1)
    viewer = profiles(:dragon_profile_1)
    assert_not Submission.filtered_for_profile(viewer, :for_profile => collaborator).include?(@collaboration_submission),
      "unapproved collaborator submission showed up on collaborator page"
  end

  # viewing anothers profile should not show any private submissions
  test "filtered for profile should not show private submissions to other profiles" do
    viewing_profile = profiles(:lion_profile_1)
    viewed_profile = profiles(:dragon_profile_1)
    private_submission = submissions(:dragon_friend_submission_1)
    assert_not Submission.filtered_for_profile(viewing_profile, :for_profile => viewed_profile).include?(private_submission),
      "a profile saw a private submission in a collection they shouldn't have"
  end

  # collaborators should see private submissions on other profiles
  test "filtered for profile should show private submissions to collaborators" do
    creator = profiles(:dragon_profile_1)
    collaborator = profiles(:lion_profile_1)
    private_submission = submissions(:dragon_friend_submission_1)
    private_submission.add_collaborator(collaborator)
    assert Submission.filtered_for_profile(collaborator, :for_profile => creator).include?(private_submission),
      "collaborator did not see a private submission they were part of when viewing creator profile"
  end

  # owner should not see your own uncollaborated images on another profile
  test "filtered for profile should not show owner images when viewing someone elses profile" do
    owner = profiles(:dragon_profile_1)
    other_profile = profiles(:dragon_profile_2)
    owner_submission = submissions(:dragon_image_1)
    assert_not Submission.filtered_for_profile(owner, :for_profile => other_profile).include?(owner_submission),
      "owner saw their submissions on someone else's profile"
  end

  test "profile can view should disallow viewing of unpublished submission" do
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    assert_not @unpublished_submission.profile_can_view?(@lion),
      "a profile saw an unpublished submission when they shouldn't have"
  end

  test "profile can view should allow viewing of unpublished submission for submission owner" do
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    assert @unpublished_submission.profile_can_view?(@dragon),
      "a submission owner was unable to view their unpublished submission"
  end

  test "profile can view should disallow viewing of a private submission" do
    assert_not submissions(:dragon_friend_submission_1).profile_can_view?(profiles(:lion_profile_1)),
               "a profile viewed a private submission they should not have"
  end

  test "profile can view should allow viewing of an owned submission" do
    assert submissions(:dragon_friend_submission_1).profile_can_view?(profiles(:dragon_profile_1)),
           "owning profile cannot view submission"
  end

  test "profile can view should allow viewing of a submission a profile is a collaborator on" do
    submission = submissions(:dragon_friend_submission_1)
    profile = profiles(:lion_profile_1)
    submission.add_collaborator(profile)
    assert submission.profile_can_view?(profile), "collaborator cannot view submission"
  end

  test "profile can view should allow filtered profiles viewing of a submission" do
    submission = submissions(:dragon_friend_submission_1)
    profile = profiles(:lion_profile_1)
    filter = filters(:dragon_friend_filter)
    assert_not submission.profile_can_view?(profile)
    filter.profiles << profile
    profile.reload
    assert submission.profile_can_view?(profile)
  end

  test "profile can view with nil profile should return false" do
    submission = submissions(:dragon_friend_submission_1)
    assert_not submission.profile_can_view?(nil)
  end

  test "add to submission group" do
    submission = submissions(:dragon_unpublished_image_1)
    submission_group = SubmissionGroup.create(profile: profiles(:dragon_profile_1))
    submission_group.add_submission(submission)
    assert_equal submission.submission_group, submission_group,
      "submission was not added to submission group"
  end

  test "image should accept paperclip options" do
    assert @submission.image(:thumb_240).include?('thumb_240')
  end

  test "can be part of a series" do
    @submission3.previous_submission = @submission2
    @submission2.previous_submission = @submission
    @submission3.save!
    @submission2.save!
    @submission3.reload
    @submission2.reload
    @submission.reload
    assert_equal @submission3, @submission2.next_submission
    assert_equal @submission2, @submission.next_submission
    assert @submission.in_series?
    assert @submission2.in_series?
    assert @submission3.in_series?
  end

  test "in series must return true or false" do
    assert_equal false, @submission2.in_series?
    @submission2.previous_submission = @submission
    @submission2.save!
    @submission2.reload
    assert_equal true, @submission2.in_series?
  end

  test "next points to the next submission in a series or returns nil if none" do
    assert_not @submission2.next_submission, "submission did not return nil for next"
    @submission2.next_submission = @submission3
    @submission2.save
    assert_equal @submission3, @submission2.next_submission, "submission didn't get assigned to next"
  end

  test "previous points to the previous submission in a series or returns nil if none" do
    assert_not @submission2.previous_submission, "submission did not return nil for previous"
    @submission2.previous_submission = @submission
    @submission2.save
    assert_equal @submission, @submission2.previous_submission, "submission didn't get assigned to next"
  end

  test "can have submissions as replies" do
    reply_submission = submissions(:dragon_image_1)
    reply_submission.replyable = @submission
    reply_submission.save!
    assert @submission.submission_replies.include?(reply_submission),
      "reply submission was not added to submission replies"
  end

  test "can have journals as replies" do
    reply_journal = journals(:dragon_journal_1)
    reply_journal.replyable = @submission
    reply_journal.save!
    assert @submission.journal_replies.include?(reply_journal),
      "reply journal was not added to submission replies"
  end

  test "can be a response to a submission" do
    reply_submission = submissions(:dragon_image_1)
    reply_submission.replyable = @submission
    assert_equal @submission, reply_submission.replyable,
      "submission did not get a replyable submission"
  end

  test "can be a response to a journal" do
    reply_submission = submissions(:dragon_image_1)
    journal = journals(:lion_journal_1)
    reply_submission.replyable = journal
    reply_submission.save!
    assert_equal journal, reply_submission.replyable,
      "submission did not get a replyable journal"
  end

  test "replies can return both submissions and journals" do
    reply_submission = submissions(:dragon_image_1)
    journal = journals(:dragon_journal_1)
    reply_submission.replyable = @submission
    reply_submission.save!
    journal.replyable = @submission
    journal.save!
    assert @submission.replies.include?(reply_submission),
      "submission did not get included in replies"
    assert @submission.replies.include?(journal),
      "journal did not get included in replies"
  end

  test "replies should not return unpublished submissions or journals" do
    reply_submission = submissions(:dragon_unpublished_image_1)
    journal = journals(:dragon_unpublished_journal_1)
    reply_submission.replyable = @submission
    reply_submission.save!
    journal.replyable = @submission
    journal.save!
    assert_not @submission.replies.include?(reply_submission),
      "unpublished submission got included in replies"
    assert_not @submission.replies.include?(journal),
      "unpublished journal got included in replies"
  end

  test "a submission cannot have a previous submission the profile is not a collaborator on" do
    unowned_submission = submissions(:dragon_image_1)
    @submission.previous_submission = unowned_submission
    assert_not @submission.save,
      "unowned submission was set as previous"
    assert_not @submission.valid?
  end

  test "a submission cannot have a next submission the profile is not a collaborator on" do
    unowned_submission = submissions(:dragon_image_1)
    assert_raises ActiveRecord::RecordNotSaved do
      @submission.next_submission = unowned_submission
    end
    @submission.reload
    assert_not_equal unowned_submission, @submission.next_submission
  end

  test "a submission cannot have a previous submission that already has a next in a series" do
    @submission2.previous_submission = @submission
    @submission2.save!
    @submission.reload
    submission_params = { profile: @submission.profile, title: 'Next' }
    new_submission = Submission.new(submission_params)
    new_submission.previous_submission = @submission
    assert_not new_submission.save,
      "submission should not have been saved"
    assert_not new_submission.valid?,
      "submission should not be valid"
    assert_no_difference 'Submission.count' do
      Submission.create(submission_params.merge({ submission_id: @submission.id }))
    end
  end

  test "approved collaborators should only return collaborators who have approved set to true" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    approved_collaborators = submission.approved_collaborators
    assert_equal 1, approved_collaborators.count,
      "there were more collaborators than expected"
    assert_not approved_collaborators.include?(@collaborator),
      "an unapproved collaborator was returned in the results"
  end

  # A submission is claimed when the owner is the same as the profile
  test "claimed" do
    submission = submissions(:dragon_lion_collaboration_image_1)
    assert_not submission.claimed?
    submission.owner = @profile
    assert_not submission.claimed?
    submission.profile = @profile
    assert submission.claimed?
  end


  test "when a submission is published, a tidbit for the profiles following the creator should be created" do
    @lion.follow_profile(@dragon)
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    assert_difference 'Tidbit.count' do
      @unpublished_submission.publish!
    end
    assert_equal @unpublished_submission, @lion.tidbits.last.targetable
  end

  test "when a filtered submission is published, profiles part of the filter should receive a tidbit" do
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    @filter = filters(:dragon_friend_filter)
    @unpublished_submission.filters << @filter
    @lion.follow_profile(@dragon)
    @filter.add_profile(@lion)
    @unpublished_submission.publish!
    assert_equal @unpublished_submission, @lion.tidbits.last.targetable
  end

  test "when a filtered submission is published, profiles not part of the filter should not receive a tidbit" do
    @unpublished_submission = submissions(:dragon_unpublished_image_1)
    @filter = filters(:dragon_friend_filter)
    @unpublished_submission.filters << @filter
    @lion.follow_profile(@dragon)
    @unpublished_submission.publish!
    assert_nil @lion.tidbits.last
  end
end