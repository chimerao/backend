class FilterProfile < ActiveRecord::Base

  belongs_to :profile
  belongs_to :filter

  validates :profile_id, uniqueness: { scope: [:filter_id] }

  scope :approved, -> { where(is_approved: true) }

end
