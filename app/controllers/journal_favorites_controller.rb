class JournalFavoritesController < FavoritesController

  private

    def get_favable
      @favable = Journal.find(params[:id])
    end
  
    def get_favorite
      @favorite = current_profile.favorites.journals.find_by_favable_id(@favable.id)
    end
end
