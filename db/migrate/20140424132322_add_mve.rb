class AddMve < ActiveRecord::Migration
  def up
  	add_column :activity_objects, :mve, :integer
  end

  def down
  end
end
