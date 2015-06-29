class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
      t.integer  :value, :default => 1
      t.timestamps
    end
    remove_column :actors, :is_admin
  end
 
  def self.down
  	add_column :actors, :is_admin, :boolean, :default => false
    drop_table :roles
  end
end