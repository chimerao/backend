class CommentVotesController < VotesController

  private

    def get_votable
      @votable = Comment.find(params[:id])
    end
  
    def get_vote
      @vote = current_profile.votes.find_by_votable_id(@votable.id)
    end
  
    def set_redirect_location
      @redirect_location = @votable.commentable
    end
end
