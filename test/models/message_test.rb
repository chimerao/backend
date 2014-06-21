require 'test_helper'

class MessageTest < ActiveSupport::TestCase

  setup do
    setup_default_profiles
    @sender = @dragon
    @recipient = @raccoon
  end

  test "sender" do
    message = create_message(@sender, @recipient)
    assert_equal @sender, message.sender
  end

  test "recipient" do
    message = create_message(@sender, @recipient)
    assert_equal @recipient, message.recipient
  end
end
