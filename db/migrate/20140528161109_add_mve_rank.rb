class AddMveRank < ActiveRecord::Migration
  def up
  	add_column :actors, :rankMve, :integer, :default => 0
  	add_column :excursions, :rankMve, :integer, :default => 0
  end

  def down
  	remove_column :actors, :rankMve
  	remove_column :excursions, :rankMve
  end
end

