class SubmissionsController < ApplicationController
  before_action :set_submission, except: [:index, :tagged]
  before_action :check_approval_access, only: [:approval, :approve, :decline]
  before_action :strict_relinquish_check, only: [:review_relinquish, :relinquish]
  before_action :use_inline_editor, only: :reply
  skip_before_filter :require_login, only: [:index, :show, :tagged]

  # GET /submissions
  # GET /submissions.json
  def index
    if current_profile
      @submissions = Submission.filtered_for_profile(current_profile, per_page: params[:per_page], page: params[:page]) # no scopes (see method)
    else
      @submissions = Submission.published.unfiltered.ordered.paginate(per_page: params[:per_page], page: params[:page])
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def show
    @folder = @submission.submission_folders.reject { |f| f == @submission.profile.submission_folder }.first
    @collaborators = [
      @submission.profile,
      @submission.approved_collaborators.reject { |c| c.id == @submission.profile_id}
    ].flatten
    @replyable = @submission.replyable
    @comment = Comment.new
    @comments = @submission.comments
 
    # View increment conditions
    if @submission.is_published? and @submission.profile != current_profile
      @submission.increment!(:views)
    end
  end

  # GET /submissions/tagged/:tag_name
  def tagged
    @submissions = Submission.published.filtered_for(current_profile).tagged_with(params[:tag_name]).ordered
    render action: 'index'
  end

  # GET /submissions/1/reply/:replyable_type
  # def reply
  #   replyable_type = params[:replyable_type].downcase
  #   if replyable_type == 'journal'
  #     @reply_journal = Journal.create(profile: current_profile, replyable: @submission)
  #     redirect_to edit_profile_journal_path(current_profile, @reply_journal)
  #   elsif replyable_type == 'submission'
  #     @submission = Submission.new(replyable: @submission)
  #     @filters = current_profile.filters
  #     tags = current_profile.submissions.tag_counts_on(:tags)
  #     tags = tags.sort_by { |tag| tag.count }.reverse
  #     @common_tags = tags.collect { |tag| tag.name }[0,8]
  #     @folders = current_profile.submission_folders.reject { |f| f.is_permanent? }
  #     render '/profile_submissions/new'
  #   end
  # end

  # GET /submissions/1/approve
  def approval
    @profiles = current_profile.user.profiles
  end

  # POST /submissions/1/approve
  # POST /submissions/1/approve.json
  def approve
    profile = Profile.find(params[:profile][:id]) if params[:profile]
    current_profile.approves!(@submission, for_profile: profile)
    respond_to do |format|
      format.html { redirect_to @submission }
      format.json { head :no_content }
    end
  end

  # DELETE /submissions/1/approve
  # DELETE /submissions/1/approve.json
  def decline
    current_profile.declines!(@submission)
    respond_to do |format|
      format.html { redirect_to dash_path }
      format.json { head :no_content}
    end
  end

  # GET /submissions/1/claim
  def request_claim
  end

  # POST /submissions/1/claim
  # POST /submissions/1/claim.json
  def claim
    current_profile.claims!(@submission)
#    flash[:notice] = "You have put in a request to get ownership of this submission."
    respond_to do |format|
      format.html { redirect_to @submission }
      format.json { head :no_content }
    end
  end

  # GET /submissions/1/relinquish
  def review_relinquish
  end

  # POST /submissions/1/relinquish
  # POST /submissions/1/relinquish.json
  def relinquish
    current_profile.relinquishes!(@submission)
#    flash[:notice] = "You have changed ownership of this submission."
    respond_to do |format|
      format.html { redirect_to @submission }
      format.json { head :no_content }
    end
  end

  private

    def set_submission
      @submission = Submission.find(params[:id])
      if @submission.submission_group or not @submission.profile_can_view?(current_profile)
        redirect_to dash_path and return false
      end
    end

    def check_approval_access
      if not @submission.collaborators.include?(current_profile)
        respond_to do |format|
          format.html { redirect_to dash_path }
          format.json { head :forbidden }
        end
        return false
      end
    end

    # An even stricter check for relinquish methods.
    # Only the actual Submission owning profile can do those.
    #
    def strict_relinquish_check
      if @submission.profile != current_profile
        respond_to do |format|
          format.html { redirect_to dash_path }
          format.json { head :forbidden }
        end
        return false
      end
    end
end
