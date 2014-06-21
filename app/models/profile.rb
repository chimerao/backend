class Profile < ActiveRecord::Base
  belongs_to :user

  has_many :comments,           dependent: :destroy
  has_many :favorite_folders,   dependent: :destroy
  has_many :favorites,          dependent: :destroy
  has_many :filters,            dependent: :destroy
  has_many :journals,           dependent: :destroy
  has_many :notifications,      dependent: :destroy
  has_many :profile_pics,       dependent: :destroy
  has_many :shares,             dependent: :destroy
  has_many :streams,            dependent: :destroy
  has_many :submission_folders, dependent: :destroy
  has_many :submissions,        dependent: :destroy
  has_many :tidbits,            dependent: :destroy
  has_many :votes,              dependent: :destroy

  has_many :collaborations,           dependent: :destroy
  has_many :collaborated_submissions, through: :collaborations, source: :submission

  has_many :filter_profiles,          dependent: :destroy
  has_many :profile_filters,          through: :filter_profiles, source: :filter

  has_many :sent_messages,     class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :recipient_id

  serialize :exposed_profiles, Array # DO NOT USE update_attribute to update this
  serialize :preferences, Hash

  validates :name, length: { maximum: 40 } #, uniqueness: { case_sensitive: false }
  validates :site_identifier, length: { maximum: 40 }, uniqueness:{ case_sensitive: false }
  validates :site_identifier, format: {
    with: /\A[a-zA-Z0-9_]+\z/,
    message: "only allows letters and underscores"
  }
  validates :bio, length: { maximum: 160 }
  validates :location, length: { maximum: 80 }
  validates :homepage, length: { maximum: 80 }
  validates :description, length: { maximum: 65000 }

  validate :ensure_only_fixnums_in_exposed_profiles
  validate :ensure_only_owned_profile_ids_in_exposed_profiles
  validate :ensure_self_is_not_in_exposed_profiles


  # Paperclip
  has_attached_file :banner_image,
                    styles: {
                      preview: '256x256>'
                    }

  validates_attachment_size :banner_image, less_than: 1.megabyte
  validates_attachment_content_type :banner_image,
                                    :content_type => [
                                      'image/gif',
                                      'image/png',
                                      'image/x-png',
                                      'image/jpg',
                                      'image/jpeg',
                                      'image/pjpeg'
                                    ]

  after_create :check_user_default_profile
  after_create :create_default_streams
  after_create :create_submission_folder
  after_create :create_favorite_folder

  # acts_as_taggable_on
  # A Profile can be tagged by other Profiles as part of "relations"
  acts_as_taggable_on :relations
  # A Profile is a tagger
  acts_as_tagger

  # Returns the default SubmissionFolder for the Profile
  #
  def submission_folder
    submission_folders.where(is_permanent: true).first
  end

  # Returns the default FavoriteFolder for the Profile
  #
  def favorite_folder
    favorite_folders.where(is_permanent: true).first
  end

  # Returns the Profile's default ProfilePic, or nil if none.
  #
  def default_profile_pic
    profile_pics.where(is_default: true).first || ProfilePic.new
  end

  # Returns whether or not the Profile has a profile pic. Useful for views.
  #
  def has_profile_pic?
    !default_profile_pic.new_record?
  end

  # This searches a string for @profile mentions and returns all the ones it finds.
  #
  def self.collect_profiles_from_string(string)
    profile_names = string.scan(/(?<=@)\w+/).collect { |name| name.downcase.strip }
    return Profile.where('LOWER(site_identifier) IN (?)', profile_names)
  end

  # Convenience method to see if a favable has been faved by the Profile.
  #
  def has_faved?(favable)
    if favable.is_a?(Journal)
      return favorites.journals.pluck(:favable_id).include?(favable.id)
    elsif favable.is_a?(Submission)
      return favorites.submissions.pluck(:favable_id).include?(favable.id)
    elsif favable.is_a?(Stream)
      return favorites.streams.pluck(:favable_id).include?(favable.id)
    end
  end

  # Convenience method to see if a shareable has been shared by the Profile.
  #
  def has_shared?(shareable)
    if shareable.is_a?(Journal)
      return shares.journals.pluck(:shareable_id).include?(shareable.id)
    elsif shareable.is_a?(Submission)
      return shares.submissions.pluck(:shareable_id).include?(shareable.id)
    end    
  end

  # Convenience method to see if a votable has been voted on by the Profile.
  #
  def has_voted_on?(votable)
    # Ineffecient. Change to a better way.
    return votes.pluck(:votable_id).include?(votable.id)
  end

  # Is the Profile in the specified Filter?
  #
  def in_filter?(filter)
    profile_filters.include?(filter) and filter_profiles.where(filter: filter).first.is_approved?
  end

  # Central method for faving an object
  #
  def fave(favable)
    favorite_folder.add_favable(favable)
  end

  # Returns all the Streams the Profile has faved (is watching)
  #
  def faved_streams
    stream_ids = favorites.streams.pluck(:favable_id)
    return Stream.find(stream_ids)
  end

  # "Follows" another profile, basically faves all of their default Streams
  #
  def follow_profile(profile)
    profile.streams.permanent.each do |stream|
      favorites.create(favable: stream)
    end
    profile.tidbits.create(targetable: self)
  end

  # "Unfollows" another profile. Unfaves all streams that may have been faved.
  #
  def unfollow_profile(profile)
    favorites.streams.where(favable_id: profile.stream_ids).each do |favorite|
      favorite.destroy
    end
    tidbit = profile.tidbits.where(targetable_id: id, targetable_type: 'Profile').first
    tidbit.destroy if tidbit
  end

  # Is this Profile following another specified profile?
  #
  def following_profile?(profile)
    return favorites.streams.where(favable_id: profile.stream_ids).count > 0
  end

  # Is this Profile following a specific stream?
  #
  def following_stream?(stream)
    return favorites.streams.pluck(:favable_id).include?(stream.id)
  end

  # Returns all the profiles that the Profile is following
  #
  def following_profiles
    stream_ids = favorites.streams.pluck(:favable_id).uniq
    profile_ids = Stream.where(id: stream_ids).pluck(:profile_id).uniq
    return Profile.where(id: profile_ids)
  end

  # Returns the count of the profiles the Profile is following
  #
  def following_profiles_count
    stream_ids = favorites.streams.pluck(:favable_id).uniq
    return Stream.where(:id => stream_ids).pluck(:profile_id).uniq.count
  end

  # Returns all the profiles that the Profile is being followed by
  #
  def followed_by_profiles
    profile_ids = Favorite.where(favable_type: 'Stream', favable_id: stream_ids).pluck(:profile_id).uniq
    return Profile.where(:id => profile_ids)
  end

  # Returns the count of the profiles the Profile is being followed by
  #
  def followed_by_profiles_count
    return Favorite.where(favable_type: 'Stream', favable_id: stream_ids).pluck(:profile_id).uniq.count
  end

  # This is a special method.
  # Because of how Stream objects work, sometimes we want to get who faved a Profile and when,
  # for dash/streams views. If one profile faves a Submission stream and another a Journal
  # stream, both count as "watches" or being "faved by." But, each watch is considered a
  # single watch, even if 3 streams were faved over time, therefore we only count the
  # furtherst back active fave as the actual "watch."
  #
  # returns Watch objects
  #
  def watched_by(options = {})
    include_followed = options.delete(:include_followed)
    include_followed = true if include_followed.nil?

    stream_ids = streams.pluck(:id)
    faved_by_favorites = Favorite.streams.where(favable_id: stream_ids)
    profile_ids = faved_by_favorites.collect { |favorite| favorite.profile_id }.uniq

    if !include_followed
      followed_stream_ids = favorites.streams.pluck(:favable_id).uniq
      profile_ids -= Stream.where(:id => followed_stream_ids).pluck(:profile_id).uniq
    end

    watches = []
    profile_ids.each do |profile_id|
      fave = faved_by_favorites.find { |favorite| profile_id == favorite.profile_id }
      watches << Watch.new(profile: fave.profile, created_at: fave.created_at, watched_profile: self)
    end
    return watches
  end

  # Similar to watched_by above, this does the opposite, returning all that the current
  # profile is "watching."
  #
  def is_watching
    faved_favorites = favorites.streams
    profile_ids = faved_favorites.collect { |favorite| favorite.favable.profile_id }.uniq
    watches = []
    profile_ids.each do |profile_id|
      fave = faved_favorites.find { |favorite| profile_id == favorite.favable.profile_id }
      watches << Watch.new(profile: fave.profile, created_at: fave.created_at, watched_profile: fave.favable.profile)
    end
    return watches
  end

  # Approves another object that was collaborated on. Currently only for Submission
  #
  # for_profile: Set another one of the User's profiles as the collaborator.
  #
  def approves!(submission, options = {})
    for_profile = options[:for_profile]
    collaboration = collaborations.where(submission: submission).first
    params = { is_approved: true }
    if for_profile and for_profile != self and user.profiles.include?(for_profile)
      params[:profile_id] = options[:for_profile].id
    end
    collaboration.update_attributes(params)
    # Remove the associated notification.
    notifications.where(notifyable_type: 'Collaboration', notifyable_id: collaboration.id).first.destroy
  end

  # Declines another object that was collaborated on. Currently only for Submission
  #
  def declines!(submission)
    collaboration = collaborations.where(submission: submission).first
    # Remove the associated notification.
    notifications.where(notifyable_type: 'Collaboration', notifyable_id: collaboration.id).first.destroy
    collaboration.destroy
  end

  # Claims a Submission for the Profile.
  # If not approved by the Submission owner, it will send a Notification
  #
  def claims!(submission)
    if not submission.claimed? and submission.owner != self
      submission.profile.notifications.create(notifyable: submission, rules: 'submission:claim')
      submission.owner = self
      submission.save
    end
  end

  # Relinquishes a Submission to another Profile
  #
  def relinquishes!(submission)
    return false if submission.profile != self
    return nil if submission.owner.nil?
    submission.profile = submission.owner
    submission.save
    notification = notifications.where(notifyable_type: 'Submission', notifyable_id: submission.id).first
    notification.destroy if notification
  end

  # True if the user has a banner image uploaded/set
  #
  def has_banner_image?
    !banner_image.path.nil?
  end

  private

    # If the User doesn't have a Profile set yet, this becomes their default one.
    #
    def check_user_default_profile
      if user.default_profile.nil?
        user.default_profile = self
      end
    end

    # Each Profile has a default set of streams which represents their whole output.
    #
    def create_default_streams
      streams.create(name: 'Submissions', is_public: true, is_permanent: true, rules: 'submissions:profile')
      streams.create(name: 'Journals', is_public: true, is_permanent: true, rules: 'journals:profile')
      streams.create(name: 'Favorites', is_public: true, is_permanent: true, rules: 'favorites:profile')
      streams.create(name: 'Comments', is_public: true, is_permanent: true, rules: 'comments:profile')
      streams.create(name: 'Shares', is_public: true, is_permanent: true, rules: 'shares:profile')
    end

    # Each Profile needs a default SubmissionFolder
    #
    def create_submission_folder
      submission_folders.create(name: 'Submissions', is_permanent: true)
    end

    # Each Profile needs a default FavoriteFolder
    #
    def create_favorite_folder
      favorite_folders.create(name: 'Favorites', is_permanent: true)
    end

    # This is here so we make sure that the data we put into the exposed profiles
    # array is clean.
    #
    def ensure_only_fixnums_in_exposed_profiles
#      if exposed_profiles.collect { |i| false if not i.is_a?(Fixnum) }.compact.size > 0
      if exposed_profiles.collect { |i| false if not i.to_i > 0 }.compact.size > 0
        errors.add(:exposed_profiles, 'can only contain Fixnums')
      end
    end

    # Also to make sure users can't add profiles they don't own.
    #
    def ensure_only_owned_profile_ids_in_exposed_profiles
      owned_profile_ids = user.profiles.pluck(:id)
      exposed_profiles.each do |profile_id|
        if not owned_profile_ids.include?(profile_id.to_i)
          errors.add(:exposed_profiles, 'can only contain valid profiles')
          break
        end
      end
    end

    # And just because, make sure self isn't included in exposed_profiles
    #
    def ensure_self_is_not_in_exposed_profiles
      if exposed_profiles.include?(id)
        errors.add(:exposed_profiles, 'should not include self')
      end
    end
end
