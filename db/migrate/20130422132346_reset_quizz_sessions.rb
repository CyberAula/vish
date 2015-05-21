class ResetQuizzSessions < ActiveRecord::Migration
  def up
  	begin
	  	drop_table :quizzes
	    drop_table :quiz_sessions
	    drop_table :quiz_answers
  	rescue
  	end

  	create_table :quiz_sessions do |t|
      t.integer :owner_id
      t.string  :name
      t.text    :quiz
      t.boolean :active, :default => true
      t.string  :url
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :closed_at
    end

    create_table :quiz_answers do |t|
      t.integer :quiz_session_id
      t.datetime :created_at
      t.text  :answer
    end
  end

  def down
    begin
      drop_table :quiz_sessions
      drop_table :quiz_answers
    rescue
    end
  end
end
