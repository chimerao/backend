class UsersController < ApplicationController
  before_action :set_page_title, only: [:new]
  before_action :set_user, only: [:edit, :update]
  skip_before_filter :require_login, only: [:new, :create]
  skip_before_filter :require_profile, only: [:index]

  PERMIT_FIELDS = [:username, :email, :password, :password_confirmation]

  wrap_parameters :user, include: PERMIT_FIELDS

  def show
    @user = current_user
    render 'show'
  end
  alias :index :show

  # GET /users/new
  # GET /signup
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html do
          login(params[:user][:email], params[:user][:password])
          redirect_to profiles_path
        end
        format.json { render action: 'show', status: :created, location: users_url }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to profiles_path, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(PERMIT_FIELDS)
    end
end