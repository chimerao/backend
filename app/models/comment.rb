class Comment < ActiveRecord::Base
  belongs_to :profile
  belongs_to :profile_pic
  belongs_to :commentable, polymorphic: true
  has_many :votes, as: :votable, dependent: :destroy
  has_many :tidbits, as: :targetable, dependent: :destroy

  # Provided for easy comment threading (separate from commentable).
  belongs_to :parent, class_name: 'Comment', foreign_key: :comment_id
  has_many :children, class_name: 'Comment', foreign_key: :comment_id

  validates :body, :profile_id, :commentable_id, :commentable_type, presence: true
  validates :body, length: { maximum: 2000 }

  after_create :create_tidbit_for_commentable,
               :create_tidbit_for_stream_faves

  # Paperclip
  has_attached_file :image,
                    storage: :filesystem,
                    styles: {
                      tiny: '60x60>',
                      small: '120x120>',
                      medium: '180x180>',
                      large: '240x240>',
                      huge: '400x400>'
                    }
  validates_attachment_size :image, less_than: 1.megabytes
  validates_attachment_content_type :image,
                                    content_type: [
                                      'image/gif',
                                      'image/png',
                                      'image/x-png',
                                      'image/jpg',
                                      'image/jpeg',
                                      'image/pjpeg'
                                    ]

  scope :ordered, -> { order(:created_at) }

  def self.filtered_submissions
    joins("INNER JOIN submissions s ON s.id = comments.commentable_id AND comments.commentable_type = 'Submission'")
    .joins('LEFT OUTER JOIN filters_submissions fs ON fs.submission_id = s.id')
    .where(['fs.filter_id IS NULL AND s.published_at <= ?', Time.now])
  end

  def self.filtered_journals
    joins("INNER JOIN journals j ON j.id = comments.commentable_id AND comments.commentable_type = 'Journal'")
    .joins('LEFT OUTER JOIN filters_journals fj ON fj.journal_id = j.id')
    .where(['fj.filter_id IS NULL AND j.published_at <= ?', Time.now])
  end

  # Determines if a Profile has access to delete/modify a Comment
  #
  def profile_has_access?(current_profile)
    current_profile and ((current_profile == profile) or (current_profile == commentable.profile))
  end

  # Comments can be poses, like, "Dragon snugs you."
  # Is the comment a pose? Meaning did someone put /me or /pose in front?
  # Should return true/false
  #
  def pose?
    /^(\/pose|\/me)/i =~ body ? true : false
  end

  def enhanced_body
    body.gsub(/^(\/pose|\/me)/i, profile.name)
  end

  # Does this Comment have an image attached?
  #
  def has_image?
    !image_file_name.blank?
  end

  private

    def create_tidbit_for_commentable
      tidbits.create(profile: commentable.profile)
    end

    def create_tidbit_for_stream_faves
      profile.streams.find_by_name('Comments').favorites.map { |fave| 
        fave.profile if commentable.profile != fave.profile and commentable.profile_can_view?(fave.profile)
      }.compact.each do |watching_profile|
        tidbits.create(profile: watching_profile)
      end
    end
end