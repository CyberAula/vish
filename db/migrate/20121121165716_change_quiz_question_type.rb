class ChangeQuizQuestionType < ActiveRecord::Migration
  def up
   change_column :quizzes, :question, :text
  end

  def down
   change_column :quizzes, :question, :string
  end
end
