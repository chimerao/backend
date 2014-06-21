class Submission < ActiveRecord::Base
  include Viewable

  has_and_belongs_to_many :submission_folders

  # The owner can be fluid. See claimed? method below.
  belongs_to :owner, class_name: 'Profile', foreign_key: :owner_id

  # Can belong to a SubmissionGroup
  belongs_to :submission_group
  has_many :collaborations, dependent: :destroy
  has_many :collaborators, through: :collaborations, source: :profile

  # Submissions can be replied to by other submissions or journals.
  belongs_to :replyable, polymorphic: true
  has_many :submission_replies, class_name: 'Submission', as: :replyable
  has_many :journal_replies, class_name: 'Journal', as: :replyable

  # Submissions can be in a sequence. Single parent/child relationship.
  belongs_to :previous_submission, class_name: 'Submission', foreign_key: :submission_id
  has_one :next_submission, class_name: 'Submission', foreign_key: :submission_id

  validates :description,  length: { maximum: 65000 }

  # Custom validations
  validate :must_own_previous_submission, :must_own_next_submission
  validate :previous_submission_cannot_have_a_next_submission

  has_attached_file :file,
                    storage: :filesystem,
                    url: "/system/submissions/:attachment/:id_partition/:style/:filename",
                    styles: {
                      thumb_64: '64x64#',
                      thumb_96: '96x96>',
                      thumb_120: '120x120>',
                      thumb_150: '150x150>',
                      thumb_180: '180x180>',
                      thumb_210: '210x210>',
                      thumb_240: '240x240>',
                      thumb_270: '270x270>',
                      thumb_300: '300x300>',
                      thumb_400: '400x400>',
                      thumb_480: '480x480>',
                      thumb_512: '512x512>',
                      resized: '1000x700>'
                    }

  DEFAULT_THUMBNAIL_SIZE = 240

  validates_attachment_size :file, less_than: 5.megabytes

  IMAGE_CONTENT_TYPES = [
    'image/gif',
    'image/png',
    'image/x-png',
    'image/jpg',
    'image/jpeg',
    'image/pjpeg'
  ]

  STORY_CONTENT_TYPES = [
    'text/plain',
#    'text/rtf',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]

  VALID_CONTENT_TYPES = [
    IMAGE_CONTENT_TYPES,
    STORY_CONTENT_TYPES
  ].flatten

  validates_attachment_content_type :file, :content_type => VALID_CONTENT_TYPES

  after_create :set_type
  after_create :set_collaborator
  after_save :set_submission_folder

  ##### Scopes

  scope :ungrouped, -> { where('submission_group_id IS NULL' ) }

  ##### Class methods

  # We need to only get submissions that the profile can view, meaning not
  # posted to a private filter they aren't on or similar.
  #
  # This seems a little messy. Basically, we cannot use @profile.collaborated_submissions
  # because of the collaborations association. For example, we can't get all
  # submissions that have collaborations.profile_id = 1 that ALSO has
  # collaborations.profile_id = 3 from submissions joining collaborations.
  #
  # Because of how submissions/collaborations are organized, it actually makes
  # more logical sense to SELECT DISTINCT submissions.* FROM collaborations
  # and the appopriate joins. (Also more query efficient too.) Since ActiveRecord
  # doesn't allow for this easily, it's best just to build a find_by_sql query.
  # The downside, however, is that we cannot use it in scope chains.
  #
  # That's okay tho. Seeing as how this will be one of the most used methods
  # for the app, it's okay to optimize it and make it a full-featured method.
  #
  def self.filtered_for_profile(profile, options = {})
    for_profile = options.delete(:for_profile)
    tags = options.delete(:tags)
    page = options.delete(:page) || 1
    per_page = options.delete(:per_page) || 30

    if tags
      tag_ids = Submission.find_by_sql(["SELECT tags.* FROM tags WHERE (lower(name) IN (?))", tags]).collect { |t| t.id }
    end

    # Lets build a raw query, shall we?
    query = ['SELECT DISTINCT s.* FROM collaborations c INNER JOIN submissions s ON s.id = c.submission_id ']
    query.first << 'LEFT OUTER JOIN filters_submissions fs ON fs.submission_id = s.id '
    query.first << 'INNER JOIN collaborations oc ON oc.submission_id = s.id ' if for_profile

    if tags
      query.first << "JOIN taggings t ON t.taggable_id = s.id AND t.taggable_type = 'Submission' AND t.tag_id IN (?)"
      query << tag_ids
    end

    query.first << 'WHERE s.published_at <= ? AND s.submission_group_id IS NULL '
    query << Time.now

    if for_profile
      query.first << 'AND (oc.profile_id = ? AND oc.is_approved = ?) '
      query << for_profile.id
      query << true
    end

    filter_ids = profile.filter_profiles.approved.pluck(:filter_id)
    query.first << 'AND (c.profile_id = ? OR fs.filter_id IS NULL OR fs.filter_id IN (?)) ORDER BY s.published_at DESC '
    query << profile.id
    query << filter_ids

    query.first << 'LIMIT ? OFFSET ?'
    query << per_page.to_i
    query << per_page.to_i * (page.to_i - 1)

    Submission.find_by_sql(query)
  end

  # Similar to above, but scopeable
  # @profile.collaborated_submissions.filtered_for(profile).published.tagged_with([tags]).ordred.limit(10)
  # Only thing it's missing is the collaborators in for_profile
  # Possibly might be where('collaborations.is_approved = true')
  # count might be a little off, tho
  #
  def self.filtered_for(profile)
    return self.unfiltered if profile.nil?
    filter_ids = profile.filter_profiles.approved.pluck(:filter_id)
    select('submissions.*')
    .from('collaborations c')
    .joins('INNER JOIN submissions ON submissions.id = c.submission_id')
    .joins('LEFT OUTER JOIN filters_submissions fs ON fs.submission_id = submissions.id')
    .where(['c.profile_id = ? OR fs.filter_id IS NULL OR fs.filter_id IN (?)', profile.id, filter_ids])
    .uniq
  end

  # Returns all journals that have no filters
  #
  def self.unfiltered
    Submission.joins('LEFT OUTER JOIN filters_submissions ON filters_submissions.submission_id = submissions.id').where('filters_submissions.filter_id IS NULL')
  end

  ##### Instance methods

  # Is the submission ready for publishing?
  # Uses Viewable method
  #
  def can_publish?
    if submission_group
      errors.add(:submission_group, 'cannot exist')
    end
    super
  end

  # Convenience method to add a collaborator and do checks.
  # Cannot user "profile" because of record relations.
  #
  def add_collaborator(p)
    collaborators << p if not collaborators.include?(p)
  end

  # Convenience method to remove a collaborator and do checks.
  # Cannot user "profile" because of record relations.
  #
  def remove_collaborator(p)
    collaborators.delete(p) if collaborators.count > 1
  end

  # Adds all @names from the description as collaborators
  #
  def add_collaborators_from_description
    return nil if description.nil?
    profiles = Profile.collect_profiles_from_string(description)
    profiles.each { |p| add_collaborator(p) }
  end

  # Returns only collaborators who have approved of themselves being
  # tagged as such, using the is_approved field of the Collaboration model.
  #
  def approved_collaborators
    profile_ids = collaborations.approved.pluck(:profile_id)
    Profile.find(profile_ids)
  end

  # A Submission is considered claimed if the profile matches the owner
  #
  def claimed?
    owner == profile
  end

  # Checks to see if a profile can view a particular Journal, checking
  # filters primarily. Can't use "profile" because of associations.
  #
  def profile_can_view?(p)
    return true if not is_filtered? and is_published?
    return false if p.nil?
    return false if not is_published? and not collaborators.include?(p)

    filter_ids = filters.pluck(:filter_id)
    profile_filter_ids = p.profile_filters.pluck(:id)
    p == profile or collaborators.include?(p) or not (profile_filter_ids & filter_ids).blank?
  end

  # Method for views to use to access the Paperclip attachment for images.
  #
  def image(options)
    file(options)
  end

  # Returns true if in a sequential series.
  # Must return true or false
  #
  def in_series?
    (submission_id or next_submission) ? true : false
  end

  # Create Tidbits for each Profile following the creator of this.
  # Called within publish! in Viewable
  #
  def create_tidbits_for_followers
    profile.streams.find_by_name('Submissions').favorites.map { |fave|
      fave.profile if profile_can_view?(fave.profile)
    }.compact.each do |watching_profile|
      tidbits.create(profile: watching_profile)
    end
  end

  private

    # Makes sure the Submission has a folder it belongs to,
    # the Profile default if none is provided.
    #
    def set_submission_folder
      if submission_folders.blank?
        profile.submission_folder.add_submission(self)
      end
    end

    # Sets the type based on the content of the file uploaded.
    # Rather important.
    #
    def set_type
      if IMAGE_CONTENT_TYPES.include?(file_content_type)
        update_attribute(:type, 'SubmissionImage')
      end
    end

    # Adds the creating profile as a collaborator. Needs to be done
    # after create so that there is always at least one.
    #
    def set_collaborator
      # Set the current_profile as the owner of the Submission
      collaboration_data = {
        :profile => profile,
        :submission => self,
        :is_approved => true
      }
      Collaboration.create!(collaboration_data)
    end

    # Custom validations
    #
    def must_own_previous_submission
      if previous_submission and not previous_submission.collaborators.include?(profile)
        errors.add(:previous_submission, 'must be collaborator on')
      end
    end

    def must_own_next_submission
      if next_submission and not next_submission.collaborators.include?(profile)
        errors.add(:next_submission, 'must be collaborator on')
      end
    end

    def previous_submission_cannot_have_a_next_submission
      if previous_submission and not previous_submission.next_submission.nil?
        errors.add(:submission_id, 'cannot have a next submission in series')
      end
    end
end
