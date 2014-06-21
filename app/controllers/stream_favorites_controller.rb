class StreamFavoritesController < FavoritesController

  def create
    if @favable.is_a?(Stream) and not @favable.is_public?
      redirect_to @redirect_location and return false
    end

    super
  end

  protected

    def get_favable
      @favable = Stream.find(params[:id])
    end
  
    def get_favorite
      @favorite = current_profile.favorites.streams.find_by_favable_id(@favable.id)
    end
  
    def set_redirect_location
      @redirect_location = profile_stream_path(@favable.profile, @favable)  
    end
end
