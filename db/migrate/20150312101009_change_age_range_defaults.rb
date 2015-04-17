class ChangeAgeRangeDefaults < ActiveRecord::Migration
  def up
  	change_column :activity_objects, :age_min, :integer, :default => 0
  	change_column :activity_objects, :age_max, :integer, :default => 0
  end

  def down
  	change_column :activity_objects, :age_min, :integer, :default => 4
  	change_column :activity_objects, :age_max, :integer, :default => 30
  end
end