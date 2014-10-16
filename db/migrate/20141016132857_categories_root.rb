class CategoriesRoot < ActiveRecord::Migration
  def up
  	remove_column :actors, :category_order
  	add_column :actors, :category_order, :text, array: true, :default => [], :null => false
  	add_column :categories, :is_root, :boolean, :default => true, :null => false
  end

  def down
  	remove_column :actors, :category_order
  	add_column :actors, :category_order, :integer
  	remove_column :categories, :is_root
  end
end
