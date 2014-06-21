class Vote < ActiveRecord::Base

  belongs_to :profile
  belongs_to :votable, polymorphic: true

  validates :profile_id, :votable_id, :votable_type, presence: true
  validates :votable_id, uniqueness: { scope: [:profile_id, :votable_type] }

end
