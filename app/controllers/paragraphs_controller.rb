class ParagraphsController < ApplicationController

    before_action :set_paragraph, only: [:show, :edit, :update, :destroy, :set_sentences, :update_words_in_mistakes]
    before_action :set_essay

def new
	@paragraph = Paragraph.new
end

def create
    @paragraph = @essay.paragraphs.create(paragraph_params) 
    @paragraph.essay_id = @essay.id
    if @paragraph.save

    end
end

def update
    if @paragraph.update(paragraph_params)
        redirect_to essay_paragraph_path(@essay, @paragraph) , notice: 'Paragraph was successfully updated.'
    end
end


def show
    update_words_in_mistakes
end

def update_words_in_mistakes
    @paragraph.sentences.each do |sen|
        sen.mistake_ids.each do |mis|
            if sen.words_in_mistakes.where(mistake_id: mis).count == 0    
            sen.words_in_mistakes.create(mistake_id: mis, paragraph_id: @paragraph.id, essay_id: @essay.id, sentence_id: sen.id)
            end
        end
    end
end



def index
    @paragraphs = Paragraph.all
end


def edit
    
end






end

 private
    # Use callbacks to share common setup or constraints between actions.
    def set_paragraph
      @paragraph = Paragraph.find(params[:id])
    end

    def set_essay
    	@essay = Essay.find(params[:essay_id])
    end



   

    # Never trust parameters from the scary internet, only allow the white list through.
    def paragraph_params
      params.require(:paragraph).permit(:content, :comment, :essay_id, :evaluation, sentences_attributes: [:id, :comment, :content, :_destroy], teacher_comment_ids:[], words_in_mistakes_attributes: [:id, :mistake_id, :sentence_id, :essay_id, :paragraph_id, :_destroy, mistake_words:[]])
    end
