class Favorite < ActiveRecord::Base

  belongs_to :profile
  belongs_to :favable, polymorphic: true
  belongs_to :favorite_folder
  has_many :tidbits, as: :targetable, dependent: :destroy

  validates :profile_id, :favable_id, :favable_type, presence: true
  validates :favable_id, uniqueness: { scope: [:profile_id, :favable_type] }

  before_create :set_favorite_folder
  after_create :create_tidbit_for_favable,
               :create_tidbit_for_stream_faves

  scope :journals, -> { where(favable_type: 'Journal' ) }
  scope :streams, -> { where(favable_type: 'Stream') }
  scope :submissions, -> { where(favable_type: 'Submission' ) }
  scope :no_streams, -> { where.not(favable_type: 'Stream') }

  def self.filtered_submissions
    joins("INNER JOIN submissions s ON s.id = favorites.favable_id AND favorites.favable_type = 'Submission'")
    .joins('LEFT OUTER JOIN filters_submissions fs ON fs.submission_id = s.id')
    .where(['fs.filter_id IS NULL AND s.published_at <= ?', Time.now])
  end

  def self.filtered_journals
    joins("INNER JOIN journals j ON j.id = favorites.favable_id AND favorites.favable_type = 'Journal'")
    .joins('LEFT OUTER JOIN filters_journals fj ON fj.journal_id = j.id')
    .where(['fj.filter_id IS NULL AND j.published_at <= ?', Time.now])
  end

  private

    # Makes sure the favorite_folder_id is populated with the Profile
    # default if none is provided.
    #
    def set_favorite_folder
      self.favorite_folder_id = profile.favorite_folder.id if favorite_folder.nil?
    end

    def create_tidbit_for_favable
      if not favable.is_a?(Stream)
        favable.profile.tidbits.create(targetable: self)
      end
    end

    def create_tidbit_for_stream_faves
      if not favable.is_a?(Stream)
        profile.streams.find_by_name('Favorites').favorites.map { |fave|
          fave.profile if favable.profile != fave.profile and favable.profile_can_view?(fave.profile)
        }.compact.each do |watching_profile|
          tidbits.create(profile: watching_profile)
        end
      end
    end
end
