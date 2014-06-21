class ProfileJournalsController < ApplicationController
  before_action :set_profile
  before_action :set_banner, except: [:new, :edit, :series]
  before_action :set_journal, only: [:edit, :update, :destroy, :publish, :series]
  before_action :use_inline_editor, only: [:new, :edit, :series]
  before_action :check_profile, except: :index
  before_action :set_filters, only: [:new, :edit, :create, :update]
  skip_before_filter :require_login, only: :index

  # Using this for both strong parameters and wrap parameters.
  PERMIT_FIELDS = [
    :title,
    :body,
    :profile_pic_id,
    :journal_id,
    { filter_ids: [] },
    :published_at,
    :replyable_id,
    :replyable_type
  ]

  wrap_parameters :journal, include: PERMIT_FIELDS.push([:tags, :filter_ids]).flatten

  # GET /profile/1/journals
  # GET /profile/1/journals.json
  def index
    if current_profile
      @journals = @profile.journals.filtered_for_profile(current_profile).published.ordered.paginate(page: params[:page], per_page: params[:per_page])
    else
      @journals = @profile.journals.unfiltered.published.ordered.paginate(page: params[:page], per_page: params[:per_page])
    end
  end

  # GET /profile/1/journals/new
  def new
    @journal = Journal.new
  end

  # GET /profile/1/journals/1/edit
  def edit
    @page_script = "IG.journal = { id: #{@journal.id}, is_published: #{@journal.is_published?} };"
  end

  # POST /profile/1/journals
  # POST /profile/1/journals.json
  def create
    @journal = Journal.new(journal_params)
    @journal.profile = current_profile
    add_tags

    if @journal.body.match(/<[^>]*>/) # it's HTML
      @journal.body.gsub!(/\s+(<\/[^>]+>)/, '\1 ')
      @journal.body = ReverseMarkdown.convert(@journal.body)
    end

    respond_to do |format|
      if @journal.save
        if @journal.published_at && @journal.published_at < Time.now + 1.minute # account for slop
          @journal.update_attribute(:published_at, nil)
          @journal.publish!
        end
        format.html { redirect_to @journal, notice: 'Journal was successfully created.' }
        format.json { render '/journals/show', status: :created, location: @journal }
      else
        format.html { render action: 'new' }
        format.json { render json: @journal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /profile/1/journals/1
  # PATCH /profile/1/journals/1.json
  def update
    add_tags

    respond_to do |format|
      if @journal.update(journal_params)
        if @journal.body.match(/<[^>]*>/) # it's HTML
          @journal.body.gsub!(/\s+(<\/[^>]+>)/, '\1 ')
          @journal.body = ReverseMarkdown.convert(@journal.body)
        end
        @journal.save
        format.html do
          redirect_to @journal, notice: 'Journal was successfully updated.'
        end
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @journal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profile/1/journals/1
  # DELETE /profile/1/journals/1.json
  def destroy
    @journal.destroy
    respond_to do |format|
      format.html { redirect_to journals_url }
      format.json { head :no_content }
    end
  end

  # PATCH /profiles/1/journals/1/publish
  # PATCH /profiles/1/journals/1/publish.json
  def publish
    respond_to do |format|
      if @journal.publish!
        format.html { redirect_to @journal, notice: 'Published!' }
        format.json { head :no_content }
      else
        format.html { redirect_to edit_profile_journal_path(@profile, @journal), notice: 'There were missing parts.' }
        format.json { render json: @journal.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /profiles/1/journals/unpublished
  # GET /profiles/1/journals/unpublished.json
  def unpublished
    @journals = @profile.journals.unpublished

    respond_to do |format|
      format.json { render 'index' }
    end
  end

  # GET /profile/1/journals/1/series
  def series
    @journal = Journal.new(previous_journal: @journal)
    @filters = current_profile.filters
    render 'new'
  end

  private

    # This is only called for creating/editing methods, so we need to check security here.
    #
    def set_journal
      @journal = Journal.find(params[:id])
      redirect_to dash_path and return false if @journal.profile != current_profile
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    #
    def journal_params
      params.require(:journal).permit(PERMIT_FIELDS)
    end

    def set_filters
      @filters = current_profile.filters    
    end

    # Take care of the tag methods separately, since they're pre-processed
    #
    def add_tags
      tag_list = params[:journal][:tags]
      if tag_list
        tag_string = tag_list.join(' ') if tag_list
        @journal.tag_list.add(sanitize_tags(tag_string))
        @journal.tag_list.add(collect_tags_from_string(params[:journal][:body]))
      end
    end
end
