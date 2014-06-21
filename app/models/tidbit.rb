class Tidbit < ActiveRecord::Base

  belongs_to :profile
  belongs_to :targetable, polymorphic: true

  scope :ordered, -> { order(created_at: :desc) }

  def action
    if targetable.is_a?(Profile)
      return 'Watch'
    else # Comment, Favorite, Share, Journal, Submission
      return targetable.class.name
    end
  end
end
