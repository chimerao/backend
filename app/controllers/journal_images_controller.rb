class JournalImagesController < ApplicationController
  before_action :set_profile
  before_action :check_profile
  before_action :set_journal, only: :index

  # GET /profiles/1/journals/1/images.json
  def index
    @journal_images = @journal.journal_images
  end

  # POST /profiles/1/journals/1/images.json
  def create
    @journal_image = JournalImage.new
    @journal_image.profile = current_profile

    # Entirely copy/pasted from profile_submissions_controller.rb
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
    ### end copy/paste

    File.open(tmp_file) do |f|
      @journal_image.image = f
    end

#    @journal_image.journal = @journal

    respond_to do |format|
      if @journal_image.save
        format.json { render 'show', status: :created, location: profile_journal_images_url(@profile, @journal, @journal_image) }
      else
        format.json { render json: @journal_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/journals/1.json
  def destroy
    @journal.journal_images.find(params[:id]).destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

    def set_journal
      @journal = current_profile.journals.find(params[:journal_id])
    end

end
