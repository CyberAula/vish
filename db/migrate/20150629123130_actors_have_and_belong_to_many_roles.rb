class ActorsHaveAndBelongToManyRoles < ActiveRecord::Migration
  def self.up
    create_table :actors_roles, :id => false do |t|
      t.references :role, :actor
    end
  end
 
  def self.down
    drop_table :actors_roles
  end
end
