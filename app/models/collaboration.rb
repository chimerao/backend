class Collaboration < ActiveRecord::Base
  belongs_to :profile
  belongs_to :submission

  validates :profile_id, uniqueness: { scope: [:submission_id] }

  after_create :send_collaborator_notifications

  scope :approved, -> { where(is_approved: true) }

  private

    def send_collaborator_notifications
      unless profile == submission.profile
        profile.notifications.create(notifyable: self, rules: 'submission:collaborator')
      end
    end
end
