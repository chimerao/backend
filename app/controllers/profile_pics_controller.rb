class ProfilePicsController < ApplicationController
  before_action :set_profile
  before_action :check_profile
  before_action :set_profile_pic, only: [:show, :destroy, :make_default]

  # GET /profiles/1/pics
  # GET /profiles/1/pics.json
  def index
    @profile_pic = ProfilePic.new
    @profile_pics = @profile.profile_pics
  end

  # GET /profiles/1/pics/1
  # GET /profiles/1/pics/1.json
  def show
  end

  # POST /profiles/1/pics
  # POST /profiles/1/pics.json
  def create
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

    @profile_pic = ProfilePic.new
    @profile_pic.profile = @profile
    File.open(tmp_file) do |f|
      @profile_pic.image = f
    end

    respond_to do |format|
      if @profile_pic.save
        format.json { render action: 'show', status: :created, location: profile_pic_url(@profile, @profile_pic) }
      else
        format.json { render json: @profile_pic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/pics/1
  # DELETE /profiles/1/pics/1.json
  def destroy
    @profile_pic.destroy
    respond_to do |format|
      format.html { redirect_to profile_pics_path(@profile) }
      format.json { head :no_content }
    end
  end

  # PATCH /profiles/1/pics/1/make_default
  # PATCH /profiles/1/pics/1/make_default.json
  def make_default
    @profile_pic.make_default!
    respond_to do |format|
      format.html { redirect_to profile_pics_path(@profile) }
      format.json { head :no_content }
    end
  end

  private

    def set_profile_pic
      @profile_pic = @profile.profile_pics.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def profile_pic_params
      params.require(:profile_pic).permit(:title, :image)
    end
end
