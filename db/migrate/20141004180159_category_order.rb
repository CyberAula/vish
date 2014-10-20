class CategoryOrder < ActiveRecord::Migration
  def up
    add_column :actors, :category_order, :text, array: true
    add_column :categories, :category_order, :text, array: true
    add_column :categories, :is_root, :boolean, :default => true
  end

  def down
    remove_column :actors, :category_order
    remove_column :categories, :category_order
    remove_column :categories, :is_root
  end
end
