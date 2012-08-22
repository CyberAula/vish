class AddSimpleJsonToQuiz < ActiveRecord::Migration
  def up
    add_column :quizzes, :simple_json, :string
  end

  def down
    remove_column :quizzes, :simple_json
  end
end
