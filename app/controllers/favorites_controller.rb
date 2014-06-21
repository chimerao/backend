class FavoritesController < ApplicationController
  before_action :get_favable
  before_action :get_favorite, only: :destroy
  before_action :set_redirect_location

  # POST /favable/1/fave
  # POST /favable/1/fave.json
  def create
    respond_to do |format|
      if current_profile.fave(@favable)
        format.html { redirect_to @redirect_location, notice: 'Faved!' }
        format.json { head :no_content }
      else
        format.html { redirect_to @redirect_location }
        format.json { render json: @favorite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /favable/1/fave
  # DELETE /favable/1/fave.json
  def destroy
    @favorite.destroy

    respond_to do |format|
      format.html { redirect_to @redirect_location }
      format.json { head :no_content }
    end
  end

  private

    # get_favable is defined in child classes (submission_favorites, journal_favorites, etc.)
    def get_favable
      raise 'get_favable is not defined in subclass'
    end
  
    # get_favorite is defined in child classes
    def get_favorite
      raise 'get_favorite is not defined in subclass'
    end
  
    # Sets the redirect location. Useful because of children classes.
    #
    def set_redirect_location
      @redirect_location = @favable
    end
end
