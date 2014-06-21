class Journal < ActiveRecord::Base
  include Viewable

  belongs_to :profile_pic

  has_many :journal_images, dependent: :destroy

  # Journals can be replied to by other journals or submissions.
  belongs_to :replyable, polymorphic: true
  has_many :submission_replies, class_name: 'Submission', as: :replyable
  has_many :journal_replies, class_name: 'Journal', as: :replyable

  # Journals can be in a sequence. Single parent/child relationship.
  belongs_to :previous_journal, class_name: 'Journal', foreign_key: :journal_id
  has_one :next_journal, class_name: 'Journal', foreign_key: :journal_id

  validates :body, length: { maximum: 65000 }

  # Custom validations
  validate :must_own_previous_journal, :must_own_next_journal
  validate :previous_journal_cannot_have_a_next_journal

  # We need to only get journals that the profile can view, meaning not
  # posted to a private filter they aren't on or similar.
  #
  def self.filtered_for_profile(profile)
    filter_ids = profile.profile_filters.pluck(:id)
    Journal.joins('LEFT OUTER JOIN filters_journals ON filters_journals.journal_id = journals.id').where(['journals.profile_id = ? OR filters_journals.filter_id IS NULL OR filters_journals.filter_id IN (?)', profile.id, filter_ids])
  end

  # Returns all journals that have no filters
  #
  def self.unfiltered
    Journal.joins('LEFT OUTER JOIN filters_journals ON filters_journals.journal_id = journals.id').where('filters_journals.filter_id IS NULL')
  end

  # Checks to see if a profile can view a particular Journal, checking
  # filters primarily. Can't use "profile" because of associations.
  #
  def profile_can_view?(p)
    return true if !is_filtered? and is_published?
    return false if p.nil?
    return false if !is_published? and p != profile

    filter_ids = filters.pluck(:filter_id)
    profile_filter_ids = p.profile_filters.pluck(:id)
    p == profile or not (profile_filter_ids & filter_ids).blank?
  end

  # Returns true if in a sequential series.
  #
  def in_series?
    (journal_id or next_journal) ? true : false
  end

  # Because we want to return an actual ProfilePic object, the default
  # profile pic should be sent if none exists on the journal, instead of
  # just passing the URL of the pic itself.
  #
  def actual_profile_pic
    profile_pic || profile.default_profile_pic
  end

  # Create Tidbits for each Profile following the creator of this.
  # Called within publish! in Viewable
  #
  def create_tidbits_for_followers
    profile.streams.find_by_name('Journals').favorites.map { |fave|
      fave.profile if profile_can_view?(fave.profile)
    }.compact.each do |watching_profile|
      tidbits.create(profile: watching_profile)
    end
  end

  private

    # Custom validations
    #
    def must_own_previous_journal
      if previous_journal and (profile != previous_journal.profile)
        errors.add(:previous_journal, 'must be owned by you')
      end
    end

    def must_own_next_journal
      if next_journal and (profile != next_journal.profile)
        errors.add(:next_journal, 'must be owned by you')
      end
    end

    def previous_journal_cannot_have_a_next_journal
      if previous_journal and not previous_journal.next_journal.nil?
        errors.add(:journal_id, 'cannot have a next journal in series')
      end
    end
end
