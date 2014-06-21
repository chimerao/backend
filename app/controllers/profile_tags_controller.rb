class ProfileTagsController < ApplicationController
  before_action :set_profile
  before_action :set_banner, only: [:index]

  # GET /profile/1/tags
  # GET /profile/1/tags.json
  def index
    @tags = @profile.relations_from(current_profile)
  end

  # POST /profile/1/tags
  # POST /profile/1/tags.json
  def create
    tags = @profile.relations_from(current_profile)
    tags << params[:tags].split(',')
    tags.flatten!
    tags.uniq!
    current_profile.tag(@profile, :with => tags.join(','), :on => :relations)

    current_profile.filters.tagged_with(tags).each do |filter|
      filter.profiles << @profile
    end

    respond_to do |format|
      format.html { redirect_to @profile }
      format.json { head :no_content }
    end
  end

  # DELETE /profile/1/tags
  # DELETE /profile/1/tags.json
  def destroy
    tag = params[:id] # 'tag'
    old_tags = @profile.relations_from(current_profile) # ['tag1', 'tag2', ...]
    new_tags = old_tags - [tag] # ['tag1', 'tag2', ...] - ['tag']
    current_profile.tag(@profile, :with => new_tags.join(','), :on => :relations) # 'tag1,tag2'

    current_profile.filters.tagged_with(tag).each do |filter|
      filter.profiles.delete(@profile)
    end

    respond_to do |format|
      format.html { redirect_to @profile }
      format.json { head :no_content }
    end
  end

end
