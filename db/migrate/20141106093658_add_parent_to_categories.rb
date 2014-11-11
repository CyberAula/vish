class AddParentToCategories < ActiveRecord::Migration
  def up
    add_column :categories, :parent_id, :integer
    remove_column :categories, :is_root
  end

  def down
    remove_column :categories, :parent_id
    add_column :categories, :is_root, :boolean
  end
end
