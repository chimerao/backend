class CommentsController < ApplicationController
  before_action :get_commentable
  skip_before_filter :require_login, only: :index

  wrap_parameters :comment, include: [:body, :comment_id, :profile_pic_id]

  # GET /commentable/1/comments.json
  def index
    @comments = @commentable.comments
  end

  # POST /commentable/1/comments
  # POST /commentable/1/comments.json
  def create
    @comment = Comment.new(comment_params)
    @comment.profile = current_profile
    @comment.commentable = @commentable

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @commentable, notice: 'Success' }
        format.json { render action: 'show', status: :created, location: polymorphic_url(@commentable) }
      else
        format.html { redirect_to @commentable }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /commentable/1/comment/1
  # DELETE /commentable/1/comment/1.json
  def destroy
    comment = @commentable.comments.find(params[:id])

    # Prevent those who don't have access from deleting the Comment.
    head :forbidden and return false if !comment.profile_has_access?(current_profile)

    comment.destroy
    respond_to do |format|
      format.html { redirect_to @commentable }
      format.json { head :no_content }
    end
  end

  private

    def get_commentable
      raise 'get_commentable is not defined in subclass'
    end
  
    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.require(:comment).permit(:body, :comment_id, :profile_pic_id, :image)
    end
end
