require 'spec_helper'

describe AnswerForm do

  context 'factory' do
    subject { build(:answer_form) }
    it{ should be_valid }
  end


  context 'callbacks' do

    it 'should generate id before create' do
      answer_form = AnswerForm.new
      answer_form.save
      expect(answer_form.id).to match /^[A-Za-z0-9]{45}\z/
    end
  end


  context 'answer methods' do

    let(:mandatory)     { create_list(:question, 2, mandatory: true) }
    let(:regular)       { create_list(:question, 2) }
    let(:questionnaire) { create(:questionnaire, questions: mandatory + regular) }
    let(:answer_form)   { create(:answer_form,   questionnaire: questionnaire) }
  
    let(:mandatory_ids) { mandatory.map(&:id) }
    let(:regular_ids)   { regular.map(&:id) }
  
    let(:full_answer)   { {}.tap{ |fa| (mandatory_ids + regular_ids).each{ |id| fa[id] = "dummy" } } }


    context '#valid_answer?' do
      
      it 'should return false for empty' do
        expect(answer_form.valid_answer?({})).to be_false
      end
  
      it 'should return true if all questions answered' do
        expect(answer_form.valid_answer?(full_answer)).to be_true
      end
  
      it 'should return true even if regular question not answered' do
        answer = full_answer.clone.tap{ |a| a.delete(regular_ids.first) }
        expect(answer_form.valid_answer?(answer)).to be_true
      end
  
      it 'should return false if mandatory question not answered' do
        answer = full_answer.clone.tap{ |a| a.delete(mandatory_ids.first) }
        expect(answer_form.valid_answer?(answer)).to be_false
      end
    end


    context '#answer' do

      it 'should not complete with an empty answer' do
        expect(answer_form.answer({})).to be_false
        expect(answer_form.completed).to be_false
      end

      it 'should complete with a full answer' do
        expect(answer_form.answer(full_answer)).to be_true
        expect(answer_form.completed).to be_true
        expect(answer_form.answers.count).to eql 4
        expect(answer_form.answers.pluck(:answer_text).uniq).to eql ['dummy']
      end
    end
  end


  it 'should find overdue' do
    regular    = create(:occasion, :date => Date.today - 10)
    wrong_date = create(:occasion, :date => Date.today - 5)
    cancelled  = create(:occasion, :date => Date.today - 10, :cancelled => true)

    create_list(:answer_form, 10, :occasion => regular)
    create(:answer_form, :occasion => regular, :completed => true)
    create(:answer_form, :occasion => wrong_date)
    create(:answer_form, :occasion => cancelled)

    result = AnswerForm.find_overdue(Date.today - 10)

    expect(result.length).to eql 10
    
    result.each do |answer_form|
      expect(answer_form.completed).to be_false
      expect(answer_form.occasion.cancelled).to be_false
      expect(answer_form.occasion.date).to eql Date.today - 10
    end
  end


end