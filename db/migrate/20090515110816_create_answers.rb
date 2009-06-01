class CreateAnswers < ActiveRecord::Migration
  def self.up
    create_table :answers do |t|
      t.integer :question_id
      t.integer :answer
      t.integer :answer_form_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :answers
  end
end
