class Watch

  attr_accessor :profile,
                :created_at,
                :watched_profile

  def initialize(options = {})
    @profile = options.delete(:profile)
    @created_at = options.delete(:created_at)
    @watched_profile = options.delete(:watched_profile)
  end

end