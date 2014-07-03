class AddQualityScoreFieldsToActivityObjects < ActiveRecord::Migration
  def up
    add_column :activity_objects, :qscore, :decimal, :precision => 12, :scale => 6
 	  add_column :activity_objects, :reviewers_qscore, :decimal, :precision => 12, :scale => 6
    add_column :activity_objects, :users_qscore, :decimal, :precision => 12, :scale => 6
  end

  def down
    remove_column :activity_objects, :qscore
    remove_column :activity_objects, :reviewers_qscore
    remove_column :activity_objects, :users_qscore
  end
end
