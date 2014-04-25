class ChangingDefaultMve < ActiveRecord::Migration
 def up
  	change_column :activity_objects, :mve, :integer, :default => 0
  end

  def down
  	change_column :activity_objects, :mve, :integer, :default => nil
  end
end
