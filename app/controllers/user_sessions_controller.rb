require 'securerandom'
require 'digest'
require 'redis'

class UserSessionsController < ApplicationController
  before_action :set_page_title, only: [:new]
  skip_before_filter :require_login, except: [:destroy]
  skip_before_filter :require_profile, only: [:destroy]

  # GET /login
  def new
    @user = User.new
  end

  # POST /login
  def create
    @user = login(params[:identifier], params[:password])

    if @user.nil?
      profile = Profile.where(['lower(site_identifier) = lower(?)', params[:identifier]]).first
      @user = login(profile.user.email, params[:password]) if profile
    end

    respond_to do |format|
      if @user
        format.html { redirect_to dash_path }
        format.json do
          render json: { token: generate_session_key_from_request }
        end
      else
        format.html do
          render action: 'new'
        end
        format.json { render json: { message: 'Invalid login.' }, status: :unprocessable_entity }
      end
    end
  end

  # GET /logout
  def destroy
    logout
    respond_to do |format|
      format.html { redirect_to root_path, notice: I18n.t('flash.logout') }
      format.json do
        redis = Redis.new
        redis.del("session_token:#{@token}")
        head :no_content
      end
    end
  end

  private

    def generate_session_key_from_request
      str = generate_unique_client_string

      redis = Redis.new
      token_set = false
      expire_time = (60 * 60 * 12) # 12 hours

      while !token_set do
        @token = SecureRandom.hex(32)
        hash = hash_from_token(@token)
        token_set = redis.set("session_token:#{@token}", [@user.id, hash].to_json, ex: expire_time, nx: true)
      end

      return @token
    end

end
