class AddTeacherQscoreField < ActiveRecord::Migration
  def up
  	add_column :activity_objects, :teachers_qscore, :decimal, :precision => 12, :scale => 6
  end

  def down
  	remove_column :activity_objects, :teachers_qscore
  end
end
