class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update, :destroy, :follow, :unfollow]
  before_action :check_profile, only: [:edit, :update]
  before_action :set_banner, only: :show
  skip_before_filter :require_login, only: :show
  skip_before_filter :require_profile, only: [:index, :new, :create]

  # Using this for both strong parameters and wrap parameters.
  PERMIT_FIELDS = [
    :name,
    :site_identifier,
    :bio,
    :location,
    :homepage,
    :is_creator,
    :banner_image,
    { exposed_profiles: [] }
  ]

  wrap_parameters :profile, include: PERMIT_FIELDS.push(:exposed_profiles)

  # GET /users/1/profiles
  # GET /users/1/profiles.json
  def index
    @profiles = current_user.profiles
  end

  # GET /profiles/1
  # GET /profiles/1.json
  def show
  end

  # GET /users/1/profiles/new
  def new
    @profile = Profile.new
    @first_profile = current_user.profiles.blank?
  end

  # GET /profiles/1/edit
  def edit
    @profiles = current_profile.user.profiles.reject { |profile| profile.id == current_profile.id }
    @other_profiles = Profile.find(current_profile.exposed_profiles)
  end

  # POST /users/1/profiles
  # POST /users/1/profiles.json
  def create
    @profile = Profile.new(profile_params)
    @profile.user = current_user
    @profile.site_identifier = params[:profile][:site_identifier]

    respond_to do |format|
      if @profile.save
#        current_user.default_profile = @profile
        set_banner
        format.html do
          redirect_to profile_home_path(@profile.site_identifier), notice: 'Profile was successfully created.'
        end
        format.json { render action: 'show', status: :created, location: profile_home_path(@profile.site_identifier) }
      else
        format.html { render action: 'new' }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profiles/1
  # PATCH/PUT /profiles/1.json
  def update
    respond_to do |format|
      # This must be update_attributes, to do validations
      if @profile.update(profile_params)
        format.html { redirect_to profile_home_path(@profile.site_identifier), notice: 'Profile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /profiles/1/banner
  def banner
    @profile = Profile.find(params[:profile_id])
    check_profile

    if request.delete?
      @profile.banner_image = nil
      @profile.save
      head :no_content
    elsif request.post?
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

      File.open(tmp_file) do |f|
        @profile.banner_image = f
      end

      if @profile.save
        render json: {
            url: "#{request.protocol}#{request.host_with_port}#{@profile.banner_image.url}",
            preview_url: "#{request.protocol}#{request.host_with_port}#{@profile.banner_image(:preview)}",
          },
          status: :ok
      else
        render json: @profile.errors, status: :unprocessable_entity
      end
    end
  end

  # DELETE /users/1/profiles/1
  # DELETE /users/1/profiles/1.json
#  def destroy
#    @profile.destroy
#    respond_to do |format|
#      format.html { redirect_to profiles_url }
#      format.json { head :no_content }
#    end
#  end

  # POST /user/1/profiles/1/switch
  # POST /user/1/profiles/1/switch.json
  def switch
    respond_to do |format|
      if profile = current_user.profiles.find_by_id(params[:id])
        current_user.default_profile = profile
        format.html { redirect_to profile_home_path(profile.site_identifier) }
        format.json { head :no_content }
      else
        format.html { redirect_to dash_path }
        format.json { head :bad_request }
      end
    end
  end

  # POST /profiles/1/follow
  # POST /profiles/1/follow.json
  def follow
    current_profile.follow_profile(@profile)
    respond_to do |format|
      format.html { redirect_to profile_home_path(@profile.site_identifier) }
      format.json { head :no_content }
    end
  end

  # DELETE /profiles/1/unfollow
  # DELETE /profiles/1/unfollow.json
  def unfollow
    current_profile.unfollow_profile(@profile)
    respond_to do |format|
      format.html { redirect_to profile_home_path(@profile.site_identifier) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile
      if params[:site_identifier]
        @profile = Profile.where(:site_identifier => params[:site_identifier]).first
      else
        @profile = Profile.find(params[:id])
      end

      if @profile.nil?
        headers['Content-Type'] = 'application/json; charset=utf-8'
        head :not_found and return false
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def profile_params
      params.require(:profile).permit(PERMIT_FIELDS)
    end
end
