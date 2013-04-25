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
      t.text    :quiz_results
      t.boolean :active, :default => true
      t.string  :url
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :closed_at
    end
  end

  def down
  	drop_table :quiz_sessions
  end
end
