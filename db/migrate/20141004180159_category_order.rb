class CategoryOrder < ActiveRecord::Migration
  def up
  	add_column :actors, :category_order, :integer
  end

  def down
  	remove_column :actors, :category_order
  end
end
