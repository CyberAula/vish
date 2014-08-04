class ChangeQuizSessionSimpleJsonType < ActiveRecord::Migration
  def up
    change_column :quizzes, :simple_json, :text
  end

  def down
    change_column :quizzes, :simple_json, :string
  end
end
