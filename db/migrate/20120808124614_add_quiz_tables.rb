class AddQuizTables < ActiveRecord::Migration
  def up
    create_table :quizzes do |t|
      t.integer :excursion_id
      t.string :type
      t.string :question
      t.string :options
    end

    create_table :quiz_sessions do |t|
      t.integer :quiz_id
      t.integer :owner_id
      t.string  :name
      t.string  :url
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean :active, :default => true
      t.datetime :closed_at
    end

    create_table :quiz_answers do |t|
      t.integer :quiz_session_id
      t.datetime :created_at
      t.string  :json
    end
  end

  def down
    drop_table :quizzes
    drop_table :quiz_sessions
    drop_table :quiz_answers
  end
end
