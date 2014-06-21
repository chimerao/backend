class MessagesController < ApplicationController
  before_action :set_profile
  before_action :check_profile, except: :new
  before_action :set_message, only: [:show, :destroy, :mark_read]

  # GET /profiles/1/messages
  # GET /profiles/1/messages.json
  def index
    if params[:mailbox] && params[:mailbox] == 'deleted'
      @messages = current_profile.received_messages.deleted.ordered
    elsif params[:mailbox] && params[:mailbox] == 'archived'
      @messages = current_profile.received_messages.undeleted.archived.ordered
    else
      @messages = current_profile.received_messages.undeleted.unarchived.ordered
    end
  end

  # GET /profiles/1/messages/1
  # GET /profiles/1/messages/1.json
  def show
  end

  # GET /profiles/1/messages/new
  def new
    @message = Message.new
    @recipient = @profile
  end

  # POST /profiles/1/messages
  # POST /profiles/1/messages.json
  def create
    @message = Message.new(message_params)
    @message.sender = current_profile
    respond_to do |format|
      if @message.save
        format.html { redirect_to profile_messages_path(@profile), notice: 'Message sent!' }
        format.json { render action: 'show', status: :created, location: [@profile, @message] }
      else
        format.html { render 'new' }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1/messages/1
  # DELETE /profiles/1/messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to profile_messages_path(@profile), notice: 'Deleted!' }
      format.json { head :no_content }
    end
  end

  # PATCH /profiles/1/messages/1/mark_read.json
  def mark_read
    @message.update_attribute(:unread, false)
    head :no_content
  end

  def bulk_delete
    @messages = current_profile.received_messages.find(params[:ids])
    @messages.each do |message|
      message.update_attribute(:deleted, true)
    end
    head :no_content
  end

  def bulk_archive
    @messages = current_profile.received_messages.find(params[:ids])
    @messages.each do |message|
      message.update_attribute(:archived, true)
    end
    head :no_content
  end

  def bulk_mark_read
    @messages = current_profile.received_messages.find(params[:ids])
    @messages.each do |message|
      message.update_attribute(:unread, false)
    end
    head :no_content    
  end

  private

    def set_message
      begin
        @message = current_profile.received_messages.find(params[:id])
      rescue
        respond_to do |format|
          format.html { redirect_to dash_path }
          format.json { head :not_found }
        end
        return false
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      permit_fields = [
        :recipient_id,
        :subject,
        :body,
        :profile_pic_id
      ]
      params.require(:message).permit(permit_fields)
    end
end
