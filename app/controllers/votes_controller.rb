class VotesController < ApplicationController
  before_action :get_votable
  before_action :get_vote, only: :destroy
  before_action :set_redirect_location

  # POST /votable/1/vote
  # POST /votable/1/vote.json
  def create
    @vote = Vote.new(:profile => current_profile, :votable => @votable)

    respond_to do |format|
      if @vote.save
        format.html { redirect_to @redirect_location, notice: 'Voted!' }
        format.json { head :no_content }
      else
        format.html { redirect_to @redirect_location, notice: 'Unvoted!' }
        format.json { render json: @votable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /votable/1/vote
  # DELETE /votable/1/vote.json
  def destroy
    @vote.destroy

    respond_to do |format|
      format.html { redirect_to @redirect_location }
      format.json { head :no_content }
    end
  end

  private

    # get_votable, get_vote, and set_redirect_location are in child classes
    def get_votable
      raise 'set_redirect_location is not defined in subclass'
    end
  
    def get_vote
      raise 'set_redirect_location is not defined in subclass'
    end
  
    def set_redirect_location
      raise 'set_redirect_location is not defined in subclass'
    end
end
