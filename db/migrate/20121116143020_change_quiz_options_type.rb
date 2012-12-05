class ChangeQuizOptionsType < ActiveRecord::Migration
  def up
   change_column :quizzes, :options, :text
  end

  def down
   change_column :quizzes, :options, :string
  end
end
