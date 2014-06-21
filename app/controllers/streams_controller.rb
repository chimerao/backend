class StreamsController < ApplicationController
  before_action :set_profile
  before_action :check_profile, only: :stream

  wrap_parameters :stream, include: [:name, :is_public, :include_journals, :include_submissions, :tags]

  def stream
    @tidbits = current_profile.tidbits.ordered.paginate(per_page: params[:per_page], page: params[:page])
  end

  # GET /dash
  def index
    if @profile == current_profile
      @streams = @profile.streams
    else
      @streams = @profile.streams.are_public
    end
  end

  # GET /profiles/1/streams/1
  def show
    @stream = @profile.streams.find(params[:id])

    # Viewability checks
    if @stream.is_permanent or (!@stream.is_public? and @profile != current_profile)      
      head :not_found and return false
    end

    @tidbits = @stream.deliver(per_page: params[:per_page], page: params[:page])
    render 'stream'
  end

  # GET /profiles/1/streams/new
  def new
    @stream = Stream.new
  end

  # POST /profiles/1/streams
  def create
    @stream = Stream.new(stream_params)
    @stream.profile = current_profile

    rules = []
    if params[:stream][:include_journals] == true
      rules << 'journals:all'
    end
    if params[:stream][:include_submissions] == true
      rules << 'submissions:all'
    end
    if params[:stream][:tags]
      tags = params[:stream][:tags].join(',')
      rules << "tags:#{tags}"
    end
    @stream.rules = rules.join(' ')

    respond_to do |format|
      if @stream.save
        format.json { render action: 'show', status: :created, location: profile_stream_url(current_profile, @stream) }
      else
        format.json { render json: @stream.errors, status: :unprocessable_entity }
      end
    end
  end

  # def create
  #   @stream = Stream.new(stream_params)
  #   @stream.profile = current_profile
  #   respond_to do |format|
  #     if @stream.save
  #       format.html { redirect_to profile_stream_path(current_profile, @stream) }
  #       format.json { render action: 'show', status: :created, location: profile_stream_path(current_profile, @stream)}
  #     else
  #       format.html { render :new }
  #       format.json { render json: @stream.errors, status: :unprocessable_entity}
  #     end
  #   end
  # end

  # PATCH /profiles/1/streams/1
  def update
    begin
      @stream = current_profile.streams.find(params[:id])
      respond_to do |format|
        if @stream.update(stream_params)
          format.html { redirect_to profile_stream_path(current_profile, @stream), notice: 'Stream was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { redirect_to profile_stream_path(current_profile, @stream) }
          format.json { render json: @stream.errors, status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to dash_path
    end
  end

  # DELETE /profiles/1/streams/1
  def destroy
    begin
      @stream = current_profile.streams.find(params[:id])    
      @stream.destroy if not @stream.is_permanent
    rescue ActiveRecord::RecordNotFound
      # do nothing
    end
    respond_to do |format|
      format.html { redirect_to dash_path }
      format.json { head :no_content }
    end    
  end

  # PATCH /profiles/1/streams/customize
  def customize
    streams = @profile.streams
    stream_ids = params[:stream_ids].map { |id| id.to_i }

    streams.each do |stream|
      if stream.profile_can_view?(current_profile)
        if stream_ids.include?(stream.id)
          current_profile.favorites.create(favable: stream)
        elsif current_profile.following_stream?(stream)
          current_profile.favorites.streams.where(favable_id: stream.id).first.destroy
        end
      end
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def stream_params
      params.require(:stream).permit(:name, :is_public)
    end
end
