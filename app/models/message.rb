class Message < ActiveRecord::Base
  belongs_to :sender,     class_name: 'Profile', foreign_key: :sender_id
  belongs_to :recipient,  class_name: 'Profile', foreign_key: :recipient_id
  belongs_to :profile_pic

  validates :sender_id, :recipient_id, :body, presence: true
  validates :subject, length: { maximum: 120 }
  validates :body, length: { maximum: 10000 }

  scope :ordered, -> { order(created_at: :desc) }
  scope :unread, -> { where(unread: true) }
  scope :undeleted, -> { where(deleted: false) }
  scope :unarchived, -> { where(archived: false) }
  scope :deleted, -> { where(deleted: true) }
  scope :archived, -> { where(archived: true) }
end
