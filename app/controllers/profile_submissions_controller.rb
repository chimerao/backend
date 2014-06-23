class ProfileSubmissionsController < ApplicationController
  before_action :set_profile
  before_action :check_profile, except: [:index, :series]
  before_action :set_banner, only: [:index]
  before_action :set_submission, only: [:edit, :update, :destroy, :publish]
  before_action :set_submission_page_script, only: [:edit, :update]
  before_action :use_inline_editor, only: [:new, :edit, :series]
  before_action :setup_submission_form, only: [:new, :edit, :series]
  skip_before_filter :require_login, only: :index

  # Using this for both strong parameters and wrap parameters.
  PERMIT_FIELDS = [
    :title,
    :description,
    :file,
    :replyable_id,
    :replyable_type,
    :submission_id,
    { filter_ids: [], submission_folder_ids: [] }
  ]

  wrap_parameters :submission, include: PERMIT_FIELDS.push([:tags, :filter_ids, :submission_folder_ids]).flatten

  # GET /profiles/1/submissions
  # GET /profiles/1/submissions.json
  def index
    if current_profile
      @submissions = Submission.filtered_for_profile(current_profile, for_profile: @profile, page: params[:page], per_page: params[:per_page]) # no scopes (see method)
    else
#      @submissions = @profile.collaborated_submissions.published.unfiltered.ordered
      @submissions = @profile.submissions.published.unfiltered.ordered.paginate(page: params[:page], per_page: params[:per_page])
    end

    respond_to do |format|
      format.html do
        @thumbnails = Chimerao::Thumbnail.build_from_images(@submissions, thumbnail_size)
      end
      format.json { render '/submissions/index' }
    end
  end

  # GET /profiles/1/submissions/new
  def new
    @submission = Submission.new
    set_submission_page_script
  end

  # POST /profiles/1/submissions
  # POST /profiles/1/submissions.json
  def create
    if request.headers['Content-Disposition']
      filename = request.headers['Content-Disposition'].split('filename=').last
      filename = filename.scan(/(?<=")[^"]+/).first if filename.include?('"')
      filename = filename.split('/').last.split('.')
      extension = filename.pop
      name = filename.join('.')
      tmp_file = "#{Rails.root}/tmp/#{name}.#{extension}"
      id = 0
      while File.exists?(tmp_file)
        id += 1
        tmp_file = "#{Rails.root}/tmp/#{name}-#{id}.#{extension}"
      end
      File.open(tmp_file, 'wb') do |f|
        f.write request.body.read
      end
      c = Cocaine::CommandLine.new('file', '-b --mime-type :file')
      mime_type = c.run(file: tmp_file).strip

      if Submission::STORY_CONTENT_TYPES.include?(mime_type)
        @submission = SubmissionStory.new
        doc = Parchment.read(tmp_file)
        @submission.description = doc.to_html.gsub('\\n', '')
      else
        @submission = Submission.new
      end
      File.open(tmp_file) do |f|
        @submission.file = f
      end

      # Dancing around strong params
      params[:submission] = {}
      params[:submission][:cheat] = "This should be rejected, but is necessary."
    else
      @submission = Submission.new(submission_params)
    end

    @submission.profile = current_profile
    @submission.save!

    FileUtils.rm(tmp_file) if tmp_file

    if 'SubmissionImage' == @submission.type
      SubmissionImage.find(@submission.id).save_metadata # needs to be done separately, for now
      @submission.reload
    end

    respond_to do |format|
      if update_submission
        format.html { redirect_to @submission, notice: 'Submission was successfully updated.' }
        format.json { render '/submissions/show', status: :created, location: submission_url(@submission) }
      else
        format.html do
          set_submission_page_script
          render action: 'edit'
        end
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profiles/1/submissions/1
  # PATCH/PUT /profiles/1/submissions/1.json
  def update
    respond_to do |format|
      if update_submission
        format.html { redirect_to @submission, notice: 'Submission was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/submissions/1
  # DELETE /profiles/1/submissions/1.json
  def destroy
    @submission.destroy
    respond_to do |format|
      format.html { redirect_to submissions_url }
      format.json { head :no_content }
    end
  end

  # GET /profiles/1/submissions/unpublished
  # GET /profiles/1/submissions/unpublished.json
  def unpublished
    @submissions = @profile.submissions.unpublished.ungrouped.order(created_at: :desc)
    @submission = Submission.new
    respond_to do |format|
      format.html { render }
      format.json { render '/submissions/index' }
    end
  end

  # PATCH /profiles/1/submissions/1/publish
  # PATCH /profiles/1/submissions/1/publish.json
  def publish
    respond_to do |format|
      if @submission.publish!
        format.html { redirect_to @submission, notice: 'Published!' }
        format.json { head :no_content }
      else
        format.html { redirect_to edit_profile_submission_path(@profile, @submission), notice: 'There were missing parts.' }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /profiles/1/submissions/group
  def group
    begin
      submissions = current_profile.submissions.find(params[:submission_ids])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'some submission ids do not exist' },
             status: :unprocessable_entity
      return false
    end

    if submissions.find { |sub| sub.is_published? }
      render json: { error: 'cannot group published submissions' },
             status: :unprocessable_entity
      return false
    end

    if submissions.size == 1
      @submission = submissions.first.submission_group
      @submission.remove_submission(submissions.first)
    else
      submission_group = submissions.find { |sub| sub.is_a?(SubmissionGroup) }
      if submission_group
        submissions = submissions.reject! { |sub| sub.is_a?(SubmissionGroup) }
      else
        # Need to do this to respect the order the ids were sent to the app
        first_submission = submissions.find { |sub| params[:submission_ids].first.to_i == sub.id }
        submission_group = first_submission.submission_group
      end

      @created = false
      if submission_group
        @submission = submission_group
      else
        @submission = SubmissionGroup.create(profile: current_profile)
        @created = true
      end

      submissions.each { |sub| @submission.add_submission(sub) }
    end

    if @submission.submissions.count == 0 # it's been destroyed
      head :no_content
    else
      render '/submissions/show',
             status: @created ? :created : :ok,
             location: submission_url(@submission)
    end
  end

  private

    # This is only called for creating/editing methods, so we need to check security here.
    #
    def set_submission
      @submission = Submission.find(params[:id])
      redirect_to dash_path and return false if @submission.profile != current_profile
    end

    # All the variables needed for the Submission form.
    def setup_submission_form
      @filters = current_profile.filters
      tags = current_profile.submissions.tag_counts_on(:tags)
      tags = tags.sort_by { |tag| tag.count }.reverse
      @common_tags = tags.collect { |tag| tag.name }[0,8]
      @folders = current_profile.submission_folders.reject { |f| f.is_permanent? }
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    #
    def submission_params
      params.require(:submission).permit(PERMIT_FIELDS)
    end

    # Method for updating a submission, used in both create and update
    #
    def update_submission
      if params[:submission][:tags].nil?
        params[:submission].delete(:tags)
      end
      if not params[:submission_ids].blank?
        # if params[:submission_ids].size > 1
        #   @submission = SubmissionGroup.new(submission_params)
        #   @submission.profile = @profile
        #   @submission.save!
        #   submissions = @profile.submissions.unpublished.where(id: params[:submission_ids])
        #   submissions.each do |sub|
        #     sub.update_attribute(:submission_group_id, @submission.id)
        #   end
        # else
          # If the submission has a blank file, that means it was recreated in response
          # to something (such as a reply to another submission or journal) we need
          # to delete it in favor of the single submission that was included.
          # But not for SubmissionGroups
          #
          if not @submission.is_a?(SubmissionGroup)
            replyable = @submission.replyable # Carry over replyable if one exists.
            @submission.destroy if @submission.file.blank?
            @submission = @profile.submissions.unpublished.find(params[:submission_ids]).first
            @submission.replyable = replyable
          end
          @submission.update!(submission_params)
        # end
      else
        @submission.update!(submission_params)
      end

      tag_list = params[:submission][:tags]
      if tag_list
        tag_string = tag_list.join(' ')
        @submission.tag_list.add(sanitize_tags(tag_string))
        @submission.tag_list.add(collect_tags_from_string(@submission.description))
      end

      if @submission.description and @submission.description.match(/<[^>]*>/) # it's HTML
        @submission.description.gsub!(/\s+(<\/[^>]+>)/, '\1 ')
        @submission.description = ReverseMarkdown.convert(@submission.description)
      end

      @submission.save

      @submission.add_collaborators_from_description

      @submission.publish! if params[:button] == 'publish'

      return true
    end

    # This is so we can pass information to javascript.
    #
    def set_submission_page_script
      @page_script = "IG.submission = { id: #{@submission.id || 'null'} };"
    end
end
