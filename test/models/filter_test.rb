require 'test_helper'

class FilterTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @profile = @dragon
    @filter = filters(:dragon_friend_filter)
  end

  test "filters should not be opt-in by default" do
    filter = @profile.filters.create(name: 'Donkeys')
    assert_not filter.opt_in
  end

  test "set url name when saving a filter" do
    filter = @profile.filters.create(name: 'New filter!')
    assert_equal "new-filter", filter.url_name
  end

  test "filter url names should be unique within a profile scope" do
    @profile.filters.create(name: 'Donkeys')
    assert_no_difference 'Filter.count' do
      @profile.filters.create(name: 'Donkeys')
    end
    assert_difference 'Filter.count' do
      @donkey.filters.create(name: 'Donkeys')
    end
  end

  test "add profile should both add and mark them as approved" do
    assert_not @filter.profiles.include?(@lion)
    assert_difference 'FilterProfile.count' do
      @filter.add_profile(@lion)
    end
    assert @filter.profiles.include?(@lion),
      "added profile was not added to the filter"
    assert @filter.approved_profile?(@lion),
      "added profile was not set as approved"
  end

  test "approved profile" do
    @filter.add_profile(@lion)
    assert @filter.approved_profile?(@lion)
  end

  test "profile request should create a filter profile record" do
    filter = filters(:lion_mane_filter)
    assert_difference 'FilterProfile.count' do
      filter.profile_request(@profile)
    end
  end

  test "profile request should create a notification to the parent profile" do
    filter = filters(:lion_mane_filter)
    before_count = filter.profile.notifications.count
    assert_difference 'Notification.count' do
      filter.profile_request(@profile)
    end
    filter.reload
    assert_equal before_count + 1, filter.profile.notifications.count
  end

  # public meaning opt-in
  test "profile request should not work on a non public filter" do
    filter = filters(:dragon_friend_filter)
    assert_no_difference 'FilterProfile.count' do
      filter.profile_request(@lion)
    end
  end

  test "profile request should not add a second request if one exists" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    assert_no_difference 'FilterProfile.count' do
      filter.profile_request(@profile)
    end
  end

  test "approve profile should set filter profile is approved to true" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    filter.approve_profile(@profile)
    assert @profile.filter_profiles.where(filter: filter).first.is_approved?    
  end

  test "approve profile should remove associated notification" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    before_count = filter.profile.notifications.count
    assert_difference 'Notification.count', -1 do
      filter.approve_profile(@profile)
    end
    filter.reload
    assert_equal before_count - 1, filter.profile.notifications.count
  end

  test "decline profile should remove associated notification" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    before_count = filter.profile.notifications.count
    assert_difference 'Notification.count', -1 do
      filter.decline_profile(@profile)
    end
    filter.reload
    assert_equal before_count - 1, filter.profile.notifications.count
  end

  test "remove profile should remove associated filter profile" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    assert_difference 'FilterProfile.count', -1 do
      filter.remove_profile(@profile)
    end
    filter.reload
    @profile.reload
    assert_not @profile.profile_filters.include?(filter)
  end

  test "remove profile should remove associated notifications" do
    filter = filters(:lion_mane_filter)
    filter.profile_request(@profile)
    before_count = filter.profile.notifications.count
    assert_difference 'Notification.count', -1 do
      filter.remove_profile(@profile)
    end
    filter.reload
    assert_equal before_count - 1, filter.profile.notifications.count
  end
end
