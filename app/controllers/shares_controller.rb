class SharesController < ApplicationController
  before_action :get_shareable
  before_action :get_share, only: :destroy
  before_action :set_redirect_location

  # POST /shareable/1/share
  # POST /shareable/1/share.json
  def create
    @share = Share.new(profile: current_profile, shareable: @shareable)

    respond_to do |format|
      if @share.save
        format.html { redirect_to @redirect_location, notice: 'Shared!' }
        format.json { head :no_content }
      else
        format.html { redirect_to @redirect_location }
        format.json { render json: @share.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shareable/1/share
  # DELETE /shareable/1/share.json
  def destroy
    @share.destroy

    respond_to do |format|
      format.html { redirect_to @redirect_location }
      format.json { head :no_content }      
    end
  end

  private

    # get_shareable is defined in child classes (submission_shares, journal_shares, etc.)
    def get_shareable
      raise 'get_shareable is not defined in subclass'
    end

    def get_share
      raise 'get_share is not defined in subclass'
    end

    # Sets the redirect location. Useful because of children classes.
    #
    def set_redirect_location
      @redirect_location = @shareable
    end
end
