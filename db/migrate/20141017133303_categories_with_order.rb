class CategoriesWithOrder < ActiveRecord::Migration
  def up
  	add_column :categories, :category_order, :text, array: true
  end

  def down
  	remove_column :categories, :category_order
  end
end
