class AddDefaultToPopularityField < ActiveRecord::Migration
  def up
    change_column :activity_objects, :popularity, :integer, :default => 0
  end

  def down
    change_column :activity_objects, :popularity, :integer, :default => nil
  end
end
