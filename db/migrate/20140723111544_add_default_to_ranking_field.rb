class AddDefaultToRankingField < ActiveRecord::Migration
  def up
    change_column :activity_objects, :ranking, :integer, :default => 0
  end

  def down
    change_column :activity_objects, :ranking, :integer, :default => nil
  end
end
