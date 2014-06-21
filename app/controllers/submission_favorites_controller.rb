class SubmissionFavoritesController < FavoritesController

  private

    def get_favable
      @favable = Submission.find(params[:id])
    end
  
    def get_favorite
      @favorite = current_profile.favorites.submissions.find_by_favable_id(@favable.id)
    end
end
