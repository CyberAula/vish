class AddMveRank < ActiveRecord::Migration
  def up
  	add_column :actors, :rankMve, :integer, :default => 0
  	add_column :excursions, :rankMve, :integer, :default => 0
  end

  def down
  end
end

