require 'test_helper'

class TidbitTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
  end

  test "should have a profile" do
    @tidbit = Tidbit.new(profile: @dragon)
    assert_equal @dragon, @tidbit.profile
  end

  test "can have a profile as a target" do
    @tidbit = Tidbit.new(profile: @dragon)
    @tidbit.targetable = @lion
    @tidbit.save
    assert_equal @lion, @tidbit.targetable
  end

  test "action should return string" do
    @tidbit = Tidbit.new(profile: @dragon, targetable: @lion)
    assert @tidbit.action.is_a?(String)
  end
end