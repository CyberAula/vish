class AddScopeToCategories < ActiveRecord::Migration
  def up
    add_column :categories, :scope, :boolean, default: true
  end

  def down
    remove_column :categories, :scope
  end
end
