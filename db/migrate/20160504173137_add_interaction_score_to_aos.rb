class AddInteractionScoreToAos < ActiveRecord::Migration
  def change
  	add_column :activity_objects, :interaction_qscore, :decimal, :precision => 12, :scale => 6
  end
end
