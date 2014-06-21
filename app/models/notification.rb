class Notification < ActiveRecord::Base

  belongs_to :profile
  belongs_to :notifyable, polymorphic: true


end
