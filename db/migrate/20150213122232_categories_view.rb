class CategoriesView < ActiveRecord::Migration
  def up
  	add_column :actors, :categories_view, :string, :default => "gallery"
  end

  def down
  	remove_column :actors, :categories_view
  end
end