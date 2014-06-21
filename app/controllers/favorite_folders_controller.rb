class FavoriteFoldersController < ApplicationController
  before_action :set_profile
  before_action :check_profile
  before_action :set_favorite_folder, only: [:show, :edit, :update, :destroy]

  # GET /profiles/1/favorite_folders
  # GET /profiles/1/favorite_folders.json
  def index
    @folders = current_profile.favorite_folders.reject { |f| f.is_permanent? }
  end

  # GET /profiles/1/favorite_folders/1
  # GET /profiles/1/favorite_folders/1.json
  def show    
  end

  # GET /profiles/1/favorite_folders/new
  def new
    @folder = FavoriteFolder.new
  end

  # GET /profiles/1/favorite_folders/edit
  def edit
  end

  # POST /profiles/1/favorite_folders
  # POST /profiles/1/favorite_folders.json
  def create
    @folder = current_profile.favorite_folders.build(submission_folder_params)

    respond_to do |format|
      if @folder.save
        format.html { redirect_to profile_favorite_folders_path, notice: 'Folder was successfully created.' }
        format.json { render action: 'show', status: :created, location: [@profile, @folder] }
      else
        format.html { render action: 'new' }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /profiles/1/favorite_folders/1
  # PATCH /profiles/1/favorite_folders/1.json
  def update
    respond_to do |format|
      if @folder.update_attributes(submission_folder_params)
        format.html { redirect_to profile_favorite_folders_path, notice: 'Folder was successfully updated.' }
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

    def set_favorite_folder
      @folder = current_profile.favorite_folders.find(params[:id])
    end

    def submission_folder_params
      params.require(:favorite_folder).permit(:name, :is_private)
    end
end
