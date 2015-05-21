class AddAdmin < ActiveRecord::Migration
  def up
  	add_column :actors, :is_admin, :boolean, :default => false
  end

  def down
  	remove_column :actors, :is_admin
  end
end
