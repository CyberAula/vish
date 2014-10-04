class CategoryOrder < ActiveRecord::Migration
  def up
  	add_column :user, :category_order, :integer
  end

  def down
  	remove_column :user, :category_order
  end
end
