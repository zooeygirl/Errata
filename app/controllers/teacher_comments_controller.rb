class TeacherCommentsController < ApplicationController

 
  before_action :set_teacher_comment, only: [:show, :edit, :update, :destroy]


def new
	@teacher_comment = current_user.teacher_comments.new
  session[:return_to] ||= request.referer
end

def create
  session[:return_to] ||= request.referer
  @teacher_comment = current_user.teacher_comments.create(teacher_comment_params) 
  @teacher_comment.user_id = current_user.id
 
  
   if @teacher_comment.save
        redirect_to session.delete(:return_to)
    end


end


def edit
  

end


def show
  
end

def index
  @teacher_comments = TeacherComment.all
end



def update
  @teacher_comment.update(teacher_comment_params)
   if @teacher_comment.update(teacher_comment_params)
        redirect_to classrooms_path
    
    end
end

 def destroy 
    @teacher_comment.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Mistake was successfully destroyed.' }
      format.json { head :no_content }
    end
  end




private
   

    def set_teacher_comment
      @teacher_comment = TeacherComment.find(params[:id])
    end

   

   def teacher_comment_params
      params.require(:teacher_comment).permit(:user_id, :category, :content)
    end
end
