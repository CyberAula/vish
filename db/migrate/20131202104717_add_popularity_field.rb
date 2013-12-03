class AddPopularityField < ActiveRecord::Migration
  def up
  	add_column :activity_objects, :popularity, :integer
  end

  def down
  	remove_column :activity_objects, :popularity  	
  end
end
