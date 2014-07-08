class AddRankingMetricsToActivityObjects < ActiveRecord::Migration
  def up
  	add_column :activity_objects, :ranking, :integer
  end

  def down
  	remove_column :activity_objects, :ranking  	
  end
end
