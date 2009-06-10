class AnswerFormController < ApplicationController
  layout "standard"
  require "pp"
  
  def index
  end

  def show

    if ( not AnswerForm.exists?(params[:answer_form_id]) )
      flash[:error] = "Ogiltig utvärderingsenkät - kontrollera addressen"
      redirect_to "/"
      return
    end

    @answer_form = AnswerForm.find(params[:answer_form_id])

    if @answer_form.completed
      flash[:error] = "Utvärderingsenkäten är redan besvarad"
      redirect_to "/"
      return
    end

    @qids = params[:question_id] unless params[:question_id].nil?
    if ( not @qids.nil? )
      if ( (@qids.keys.map { |k| k.to_i } - @answer_form.questionaire.question_ids).empty? )
        # All questions answered - update answer_form , create answer objects and thank the user
        @qids.each do |qid , ans|
          puts "Creating answer for qid = #{qid} answer = #{ans}"
          answer = Answer.new
          answer.question_id = qid
          answer.answer = ans.to_i
          answer.answer_form = @answer_form
          answer.save
        end
        @answer_form.completed = true
        @answer_form.save
        flash[:notice] = "Tack för att du svarade på utvärderingsenkäten"
        redirect_to "/"
        return
      end
    end

    render "show"
  end

  
  def reply
    @answer_form = AnswerForm.find(params[:answer_form_id])
  end

end