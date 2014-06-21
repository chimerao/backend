class Share < ActiveRecord::Base

  belongs_to :profile
  belongs_to :shareable, polymorphic: true
  has_many :tidbits, as: :targetable, dependent: :destroy

  validates :profile_id, :shareable_id, :shareable_type, presence: true
  validates :shareable_id, uniqueness: { scope: [:profile_id, :shareable_type] }

  after_create :create_tidbit_for_shareable,
               :create_tidbit_for_stream_faves

  scope :journals, -> { where(shareable_type: 'Journal' ) }
  scope :submissions, -> { where(shareable_type: 'Submission' )}

  def self.filtered_submissions
    joins("INNER JOIN submissions s ON s.id = shares.shareable_id AND shares.shareable_type = 'Submission'")
    .joins('LEFT OUTER JOIN filters_submissions fs ON fs.submission_id = s.id')
    .where(['fs.filter_id IS NULL AND s.published_at <= ?', Time.now])
  end

  def self.filtered_journals
    joins("INNER JOIN journals j ON j.id = shares.shareable_id AND shares.shareable_type = 'Journal'")
    .joins('LEFT OUTER JOIN filters_journals fj ON fj.journal_id = j.id')
    .where(['fj.filter_id IS NULL AND j.published_at <= ?', Time.now])
  end

  private

    def create_tidbit_for_shareable
      shareable.profile.tidbits.create(targetable: self)
    end

    def create_tidbit_for_stream_faves
      profile.streams.find_by_name('Shares').favorites.map { |fave|
        fave.profile if shareable.profile != fave.profile and shareable.profile_can_view?(fave.profile)
      }.compact.each do |watching_profile|
        tidbits.create(profile: watching_profile)
      end
    end
end
