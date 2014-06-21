class SubmissionSharesController < SharesController

  private

    def get_shareable
      @shareable = Submission.find(params[:id])
    end

    def get_share
      @share = current_profile.shares.submissions.find_by_shareable_id(@shareable.id)
    end
end
