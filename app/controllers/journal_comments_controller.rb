class JournalCommentsController < CommentsController

  private

    def get_commentable
      @commentable = Journal.find(params[:journal_id])
    end
end
