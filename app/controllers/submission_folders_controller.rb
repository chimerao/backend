class SubmissionFoldersController < ApplicationController
  before_action :set_profile
  before_action :check_profile, except: :show
  before_action :set_submission_folder, only: [:show, :edit, :update, :destroy]
  skip_before_filter :require_login, only: :show

  # GET /profiles/1/submission_folders
  # GET /profiles/1/submission_folders.json
  def index
    @folders = current_profile.submission_folders.reject { |f| f.is_permanent? }
  end

  # GET /profiles/1/submission_folders/1
  # GET /profiles/1/submission_folders/1.json
  def show
    @submissions = @folder.submissions
  end

  # GET /profiles/1/submission_folders/new
  def new
    @folder = SubmissionFolder.new
    @filters = current_profile.filters
  end

  # GET /profiles/1/submission_folders/edit
  def edit
    @filters = current_profile.filters
  end

  # POST /profiles/1/submission_folders
  # POST /profiles/1/submission_folders.json
  def create
    @folder = current_profile.submission_folders.build(submission_folder_params)

    respond_to do |format|
      if @folder.save
        format.html { redirect_to profile_submission_folders_path, notice: 'Folder was successfully created.' }
        format.json { render action: 'show', status: :created, location: [@profile, @folder] }
      else
        format.html { render action: 'new' }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /profiles/1/submission_folders/1
  # PATCH /profiles/1/submission_folders/1.json
  def update
    respond_to do |format|
      if @folder.update_attributes(submission_folder_params)
        format.html { redirect_to profile_submission_folders_path, notice: 'Folder was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/submission_folders/1
  # DELETE /profiles/1/submission_folders/1.json
  def destroy
    @folder.destroy
    respond_to do |format|
      format.html { redirect_to profile_favorite_folders_path }
      format.json { head :no_content }
    end
  end

  private

    def set_submission_folder
      @folder = @profile.submission_folders.find(params[:id])
    end

    def submission_folder_params
      params.require(:submission_folder).permit(:name, { filter_ids: [] })
    end
end
