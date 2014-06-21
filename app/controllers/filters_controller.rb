class FiltersController < ApplicationController
  before_action :set_filter, only: [:show, :join, :leave]
  before_action :set_profile

  # GET /profiles/1/filters
  # GET /profiles/1/filters.json
  def index
    if @profile == current_profile
      @filters = @profile.filters
    else
      @filters = @profile.filters.opt_in
    end
  end

  # GET /profiles/1/filters/1
  # GET /profiles/1/filters/1.json
  def show
  end

  # GET /profiles/1/filters/new
  def new
    @filter = Filter.new
  end

  # GET /profiles/1/filters/1/edit
  def edit
    @filter = current_profile.filters.find(params[:id])
  end

  # POST /profiles/1/filters
  # POST /profiles/1/filters.json
  def create
    @filter = Filter.new(filter_params)
    @filter.profile = current_profile

    respond_to do |format|
      if @filter.save
        format.html { redirect_to [@profile, @filter], notice: 'Filter was successfully created.' }
        format.json { render action: 'show', status: :created, location: [@profile, @filter] }
      else
        format.html { render action: 'new' }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /profiles/1/filters/1
  # PATCH /profiles/1/filters/1.json
  def update
    @filter = current_profile.filters.find(params[:id])
    respond_to do |format|
      if @filter.update(filter_params)
        format.html { redirect_to [@profile, @filter], notice: 'Filter was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/filters/1
  # DELETE /profiles/1/filters/1.json
  def destroy
    @filter = current_profile.filters.find(params[:id])
    @filter.destroy
    respond_to do |format|
      format.html { redirect_to profile_filters_path(current_profile) }
      format.json { head :no_content }
    end
  end

  # POST /profiles/1/filters/1/join
  # POST /profiles/1/filters/1/join.json
  def join
    @filter.profile_request(current_profile)
    respond_to do |format|
      format.html do
#        flash[:notice] = "Your request to join #{@profile.name}'s #{@filter.name} filter has been sent."
        redirect_to profile_home_path(@profile.url_name)
      end
      format.json { head :no_content }
    end
  end

  # DELETE /profiles/1/filters/1/join
  # DELETE /profiles/1/filters/1/join.json
  def leave
    @filter.remove_profile(current_profile)
    respond_to do |format|
      format.html { redirect_to [@profile, @filter] }
      format.json { head :no_content }
    end
  end

  private

    def set_filter
      @filter = Filter.find(params[:id])
    end
  
    # Never trust parameters from the scary internet, only allow the white list through.
    def filter_params
      params.require(:filter).permit(:name, :description, :opt_in)
    end

end
