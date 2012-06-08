class AddRecommenderFields < ActiveRecord::Migration
  def up
    add_column :activity_objects, :language, :string
    add_column :activity_objects, :age_min, :integer, :default => 4
    add_column :activity_objects, :age_max, :integer, :default => 30
  end

  def down
    remove_column :activity_objects, :language
    remove_column :activity_objects, :age_min
    remove_column :activity_objects, :age_max
  end
end
