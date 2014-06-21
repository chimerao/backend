class JournalsController < ApplicationController
  before_action :set_journal
  skip_before_filter :require_login

  # GET /journals/1
  # GET /journals/1.json
  def show
    if not @journal.profile_can_view?(current_profile)
      respond_to do |format|
        format.html { redirect_to dash_path }
        format.json { head :not_found }
      end
      return false
    end
    @profile = @journal.profile
    @comment = Comment.new
    @comments = @journal.comments
    if @journal.is_published? and @journal.profile != current_profile
      @journal.increment!(:views)
    end
  end

  # GET /journals/1/reply/:replyable_type
  def reply
    replyable_type = params[:replyable_type].downcase
    if replyable_type == 'journal'
      @reply_journal = Journal.create(profile: current_profile, replyable: @journal)
      redirect_to edit_profile_journal_path(current_profile, @reply_journal)
    elsif replyable_type == 'submission'
      @reply_submission = Submission.create(profile: current_profile, replyable: @journal)
      redirect_to edit_profile_submission_path(current_profile, @reply_submission)
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_journal
      @journal = Journal.find(params[:id])
    end
end
