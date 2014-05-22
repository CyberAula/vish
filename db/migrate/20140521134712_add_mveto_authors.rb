class AddMvetoAuthors < ActiveRecord::Migration
  def up
  	add_column :actors, :mve, :integer, :default => 0
  	add_column :actors, :is_mve, :boolean, :default => false
  	add_column :excursions, :is_mve, :boolean, :default => false 
  end

  def down
  end
end
