class FilterProfilesController < ApplicationController
  before_action :set_profile
  before_action :check_profile
  before_action :set_filter
  before_action :set_member, except: :index

  def index
    @members = @filter.filter_profiles
  end

  def create
    @filter.add_profile(@member)
    respond_to do |format|
      format.html { redirect_to [@profile, @filter] }
      format.json do
        @profile = @member
        render 'profiles/show'
      end
    end
  end

  def destroy
    @filter.profiles.delete(@member)
    respond_to do |format|
      format.html { redirect_to [@profile, @filter] }
      format.json { head :no_content }
    end
  end

  def review_join
  end

  def approve
    @filter.approve_profile(@member)
    respond_to do |format|
      format.html { redirect_to [@profile, @filter] }
      format.json { head :no_content }
    end
  end

  def decline
    @filter.decline_profile(@member)
    respond_to do |format|
      format.html { redirect_to [@profile, @filter] }
      format.json { head :no_content }
    end    
  end

  private

    def set_filter
      @filter = @profile.filters.find(params[:filter_id])
    end
  
    def set_member
      if params[:site_identifier]
        name = params[:site_identifier].gsub('@', '')
        @member = Profile.find_by_site_identifier(name)
      else
        @member = Profile.find(params[:id])
      end
    end
end
