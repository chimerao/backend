class SubmissionCommentsController < CommentsController

  private

    def get_commentable
      @commentable = Submission.find(params[:submission_id])    
    end
end
