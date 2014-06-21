require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:dragon)
  end

  test "default profile" do
    assert_equal profiles(:dragon_profile_1), @user.default_profile
  end

  test "set default profile" do
    profile = profiles(:dragon_profile_2)
    assert_equal profiles(:dragon_profile_1), @user.default_profile
    @user.default_profile = profile
    assert_equal profile, @user.default_profile
  end

  test "set default profile cannot be set to nil" do
    profile = profiles(:dragon_profile_1)
    assert_equal profile, @user.default_profile
    @user.default_profile = nil
    assert_equal profile, @user.default_profile
  end
end
