class AddMve < ActiveRecord::Migration
  def up
  	add_column :excursions, :mve, :integer, :default => 0
  end

  def down
  	remove_column :excursions, :mve
  end
end
