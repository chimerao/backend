class NotificationsController < ApplicationController
  before_action :set_profile
  before_action :check_profile

  # GET /profiles/1/notifications
  # GET /profiles/1/notifications.json
  def index
    @notifications = @profile.notifications
  end
end
