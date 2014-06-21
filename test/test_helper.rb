ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# User authentication gem
include Sorcery::TestHelpers::Rails

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Helper to easily set the current_profile for tests.
  # Uses @profile if none is given.
  def set_profile(profile = nil)
    raise '@user needs to be defined for set_profile' if @user.nil?
    @user.default_profile = profile || @profile
  end

  # An easy way to set the common profiles used in tests
  def setup_default_profiles
    @dragon = profiles(:dragon_profile_1)
    @donkey = profiles(:dragon_profile_2)
    @lion = profiles(:lion_profile_1)
    @raccoon = profiles(:raccoon_profile_1)
  end

  def setup_json_api
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'application/json'
  end

  # Nice simple method for quickly creating messages between profiles.
  def create_message(sender, recipient, options = {})
    create_options = {
      sender: sender,
      recipient: recipient,
      body: 'Hi there!'
    }
    Message.create!(create_options.merge(options))
  end
end
