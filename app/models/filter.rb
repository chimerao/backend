class Filter < ActiveRecord::Base

  belongs_to :profile
  has_many :filter_profiles
  has_many :profiles, through: :filter_profiles

  validates :url_name,    uniqueness: { scope: :profile_id }
  validates :name,        length: { maximum: 30 }
  validates :description, length: { maximum: 255 }

  acts_as_taggable

  before_validation :set_url_name

  scope :opt_in, -> { where(opt_in: true) }

  # Adds a member and immediately approves them.
  # For use when a Profile manually adds others to a filter.
  #
  def add_profile(member)
    filter_profiles.create(profile: member, is_approved: true)
  end

  # Method to determine if a profile is approved.
  #
  def approved_profile?(member)
    filter_profiles.approved.pluck(:profile_id).include?(member.id)
  end

  # A method to use when reqeusting to join the filter
  #
  def profile_request(requesting_profile)
    if opt_in
      fp = filter_profiles.create(profile: requesting_profile)
      if fp.valid?
        profile.notifications.create(notifyable: fp, rules: 'filter:request')
      end
    end
  end

  # Approve a profile that has made a previous request
  #
  def approve_profile(requesting_profile)
    fp = requesting_profile.filter_profiles.where(filter: self).first
    fp.update_attribute(:is_approved, true)
    notification = profile.notifications.where(notifyable: fp).first
    notification.destroy if notification
  end

  def decline_profile(requesting_profile)
    remove_profile(requesting_profile)
  end

  def remove_profile(filtered_profile)
    fp = filtered_profile.filter_profiles.where(filter: self).first
    notification = profile.notifications.where(notifyable: fp).first
    fp.destroy
    notification.destroy if notification
  end

  private

    # We need url_title to be a unique, URI-safe identifier.
    #
    def set_url_name
      self.url_name = name.gsub(/\s/, "-").gsub(/[^a-zA-Z0-9-]/, "").downcase
    end
end
