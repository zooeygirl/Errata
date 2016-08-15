class EssaysController < ApplicationController
  before_action :set_essay, only: [:show, :edit, :update, :destroy, :second_draft, :count_mistakes, :set_paragraphs, :set_sentences]
  before_action :authenticate_user!, except: [:index, :show]



  # GET /essays
  # GET /essays.json
  def index
    @essays = Essay.all
  end



  def show
    find_classroom
    count_mistakes
  end

def set_paragraphs_for_second_draft
  @essay = Essay.find(params[:essay_id])
  @paragraphs = @essay.body.split(/\r\n\r\n/)
    i=0
    @sentences_in_paragraph = []
    while i < @paragraphs.count do
      if @essay.paragraphs[i] == nil
      @essay.paragraphs.create(content: @paragraphs[i])
      else
      @essay.paragraphs[i].update(content: @paragraphs[i])
      end
    @sentences_in_paragraph[i] = Scalpel.cut(@paragraphs[i]).count
    i+= 1
    end

     if @essay.paragraphs.count > @paragraphs.count
                for j in @paragraphs.count..@essay.paragraphs.count
                  if @essay.paragraphs[j] != nil
                  @essay.paragraphs.delete(Paragraph.find(@essay.paragraphs[j].id))
                  end
                end
      end
    set_sentences
    redirect_to essay_path(@essay)
end

def set_paragraphs
    @paragraphs = @essay.body.split(/\r\n\r\n/)
    i=0
    @sentences_in_paragraph = []
    while i < @paragraphs.count do
      if @essay.paragraphs[i] == nil
      @essay.paragraphs.create(content: @paragraphs[i])
      else
      @essay.paragraphs[i].update(content: @paragraphs[i])
      end
    @sentences_in_paragraph[i] = Scalpel.cut(@paragraphs[i]).count
    i+= 1
    end

     if @essay.paragraphs.count > @paragraphs.count
                for j in @paragraphs.count..@essay.paragraphs.count
                  if @essay.paragraphs[j] != nil
                  @essay.paragraphs.delete(Paragraph.find(@essay.paragraphs[j].id))
                  end
                end
      end
    set_sentences
    if @essay.draftnum == 2
      redirect_to essay_path(Essay.find(@essay.trackernum))
    end    
end


  # GET /essays/new
  def new
    @essay = current_user.essays.build(essay_params)
  end

  # GET /essays/1/edit
  def edit
    
  end

  # POST /essays
  # POST /essays.json
  def create
    @essay = current_user.essays.build(essay_params)
    @essay.user_id = current_user.id
    @essay.essay_status = 0
    @essay.trackernum = @essay.id
    @essay.draftnum = 1
    @essay.teacher = current_user.teacher
    
    respond_to do |format|
      if @essay.save
        set_paragraphs
        turn_word_list_into_an_array
        format.html { redirect_to @essay, notice: 'Essay was successfully created.' }
        format.json { render :show, status: :created, location: @essay }
      else
        format.html { render :new }
        format.json { render json: @essay.errors, status: :unprocessable_entity }
      end
    end

  end



  # PATCH/PUT /essays/1
  # PATCH/PUT /essays/1.json
  def update
    respond_to do |format|
      if @essay.update(essay_params)
        set_paragraphs
        turn_word_list_into_an_array
        calculate_student_grade

        format.html { redirect_to :back, notice: 'Essay was successfully updated.' }
        format.json { render :show, status: :ok, location: @essay }
        
      else
        format.html { render :edit }
        format.json { render json: @essay.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /essays/1
  # DELETE /essays/1.json
  def destroy
    @essay.destroy
    respond_to do |format|
      format.html { redirect_to essays_url, notice: 'Essay was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def find_classroom
    student = User.find(@essay.user_id)
    @classroom = Classroom.find(student.classroom)
  end

  def submit_essay
    @essay = Essay.find(params[:essay_id])
    @essay.update_attribute(:essay_status, 1)
    redirect_to essays_path, notice: "You have successfully submitted your essay"
  end

  def give_feedback
    @essay = Essay.find(params[:essay_id])
    @ungraded_sections = []
        @essay.grade_elements.each do |ge|
          if ge.teachereval == nil
            @ungraded_sections += [ge.level]
          end
        end
    if @ungraded_sections.count > 0 && @essay.paragraphs.count > 1
        redirect_to :back, notice: "Some sections of the essay have not yet been graded. #{@ungraded_sections}"
    else
      @essay.update_attribute(:essay_status, 2)
      secondcopy = @essay.dup
      secondcopy.update_attribute(:trackernum, @essay.id)
      secondcopy.update_attribute(:draftnum, 2)
      redirect_to classroom_path(Assignment.find(@essay.assignment_id).classroom_id), notice: "Your feedback has been given to the student."
    end
  end

  def create_grade_template
    @essay = Essay.find(params[:essay_id])
    if @essay.grade_elements.blank?
    @assignment = Assignment.find(@essay.assignment_id)
    @evaluation = Evaluation.find(@assignment.evaluation)
    @evaluation.criteria.each do |crit|
      if crit.level == 'All Paragraphs'
        @essay.paragraphs.each do |para|
          @essay.grade_elements.create(level: crit.level, name: crit.name, percentage: crit.percentage/@essay.paragraphs.count, outof: crit.outof, essay_id: @essay.id, paragraph_id: para.id)
        end
      elsif crit.level == 'Essay'
        @essay.grade_elements.create(level: crit.level, name: crit.name, percentage: crit.percentage, outof: crit.outof, essay_id: @essay.id)
      elsif crit.level == 'Introduction'
        @essay.grade_elements.create(level: crit.level, name: crit.name, percentage: crit.percentage, outof: crit.outof, essay_id: @essay.id, paragraph_id: @essay.paragraphs.first.id)
      elsif crit.level == 'Conclusion'
        @essay.grade_elements.create(level: crit.level, name: crit.name, percentage: crit.percentage, outof: crit.outof, essay_id: @essay.id, paragraph_id: @essay.paragraphs.last.id)
      elsif crit.level == 'Body Paragraph'
        @essay.paragraphs[1..@essay.paragraphs.count-2].each do |para|
          @essay.grade_elements.create(level: crit.level, name: crit.name, percentage: crit.percentage/(@essay.paragraphs.count-2), outof: crit.outof, essay_id: @essay.id, paragraph_id: para.id)
        end
      end          
    end
    redirect_to essay_path(@essay)
    else
    redirect_to essay_path(@essay)
    end  
  end

def calculate_student_grade
  i=0
  @essay.grade_elements.each do |ge|
    if ge.level == 'Essay' || ge.level == 'Introduction' || ge.level == 'Conclusion'
      if ge.teachereval != nil
      i += ge.teachereval/ge.outof * ge.percentage
      end
    elsif ge.level == 'All Paragraphs'
      if ge.teachereval != nil
      i += ge.teachereval/ge.outof * ge.percentage
      end
    elsif ge.level == 'Body Paragraph'
      if ge.teachereval != nil
      i += ge.teachereval/ge.outof * ge.percentage
      end
    end
    @essay.update_attribute(:studentgrade, i)
  end
end

def change_rubric
  @essay = Essay.find(params[:essay_id])
  @essay.grade_elements.each do |ge|
    ge.destroy
  end
  @essay.update_attribute(:studentgrade, 0)
  create_grade_template
end
 
   


  def count_mistakes
    if @essay.trackernum == nil
    essay = @essay
    else
    essay = Essay.find(@essay.trackernum)
    end
    @num_mistakes = 0
      essay.sentences.each do |sen|
      @num_mistakes += sen.mistake_ids.count
    end

    return @num_mistakes
  end


  def turn_word_list_into_an_array
      @essay.paragraphs.each do |para|
            para.sentences.each do |sen|
            i = 0
            while i < sen.word_list.count do
            sen.word_list[i] = [i.to_s, sen.word_list[i]] 
            i+=1
            end
            sen.update(word_list: sen.word_list)
            end
      end
  end

  
  def set_sentences

          @essay.paragraphs.each do |paragraph|

              @sentence_array = Scalpel.cut(paragraph.content)
        
              i=0

              while i < @sentence_array.count  do
                if paragraph.sentences[i].blank?
                    paragraph.sentences.create(content: @sentence_array.at(i), essay_id: @essay.id, word_list: @sentence_array.at(i).split(/\W+/))
                else
                    paragraph.sentences[i].update(content: @sentence_array.at(i), essay_id: @essay.id, word_list: @sentence_array.at(i).split(/\W+/))
                end

              i +=1
              end

              if paragraph.sentences.count > @sentence_array.count
                for j in @sentence_array.count..paragraph.sentences.count
                  if paragraph.sentences[j] != nil
                  paragraph.sentences.destroy(Sentence.find(paragraph.sentences[j].id))
                  end
                end
              end

          end
    end




  private
    # Use callbacks to share common setup or constraints between actions.
    def set_essay
      @essay = Essay.find(params[:id])
    end


     



    # Never trust parameters from the scary internet, only allow the white list through.
    def essay_params
      params.require(:essay).permit(:title, :body, :user_id, :essay_status, :studentgrade, :draftnum, :trackernum, :assignment_id, :teacher, grade_elements_attributes: [:id, :teachereval, :_destroy], paragraphs_attributes: [:id, :sentences, :_destroy], sentences_attributes: [:id, :comment, :_destroy, mistake_ids:[]], words_in_mistakes_attributes: [:id, :_destroy, mistake_words:[]])
    end

end