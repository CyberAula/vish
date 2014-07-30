class AddScopeToActivityObjects < ActiveRecord::Migration
  def up
    add_column :activity_objects, :scope, :integer, :default => 0
  end

  def down
    remove_column :activity_objects, :scope
  end
end
