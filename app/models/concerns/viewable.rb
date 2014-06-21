require 'active_support/concern'

# Both Submission and Journal objects have a lot of similarities,
# because they're primary viewable objects. Things like view counts,
# comments, etc. Therefore, it makes sense to have a lot of identical
# methods in a added module.
#
module Viewable
  extend ActiveSupport::Concern

  included do
    belongs_to :profile
    has_and_belongs_to_many :filters, -> { uniq }
    has_many :comments,   as: :commentable, dependent: :destroy
    has_many :favorites,  as: :favable,     dependent: :destroy
    has_many :shares,     as: :shareable,   dependent: :destroy
    has_many :tidbits,    as: :targetable,  dependent: :destroy

    acts_as_taggable

    validates :title, presence: true, if: :published_at
    validates :title, length: { maximum: 80 }

    before_validation :set_url_title

    scope :published, -> { where('published_at <= ?', Time.now) }
    scope :unpublished, -> { where('published_at IS NULL OR published_at > ?', Time.now) }
    scope :ordered, -> { order(published_at: :desc) }
  end

  # Publishes a Viewable
  # This is where we need to perform any validations
  #
  def publish!
    return false if not can_publish?
    update_attribute(:published_at, Time.now)
    create_tidbits_for_followers
    return true
  end

  # Is the Viewable published? (able to be viewed by others)
  # Must return true or false, not nil or otherwise
  #
  def is_published?
    if published_at and published_at <= Time.now
      return true
    else
      return false
    end
  end

  # Is the Viewable ready for publishing?
  #
  # The reason I use the publishable variable is just to add
  # custom error messages.
  #
  def can_publish?
    if title.nil? or title.blank?
      errors.add(:title, 'cannot be blank')
    end
    if is_published?
      errors.add(:published_at, 'cannot be in the past')
    end
    errors.count == 0
  end

  # Ratings are mostly handled by tags.
  #
  def is_adult?
    adult_tags = %w(adult explicit nsfw)
    !(adult_tags & tag_list).blank?
  end

  # Is the Viewable filtered? Convenience method.
  #
  def is_filtered?
    filters.count > 0
  end

  # The following methods are the Viewable object's counting methods.
  # The reason they're used instead of just the plain association is if we
  # change or optimize how they're calculated, we only have to change
  # a single method.
  #
  def comments_count
    comments.count
  end

  def favorites_count
    favorites.count
  end

  def views_count
    views
  end

  def shares_count
    shares.count
  end

  # Get all replies (journals, submissions, etc.) for the Submission
  #
  def replies
    [submission_replies.published, journal_replies.published].flatten
  end

  private

    # We need url_title to be a URI-safe identifier.
    #
    def set_url_title
      return nil if title.nil?
      adjusted_title = title.gsub(/\s/, "-").gsub(/[^a-zA-Z0-9-]/, "").downcase
      self.url_title = "#{adjusted_title}"
    end

end
