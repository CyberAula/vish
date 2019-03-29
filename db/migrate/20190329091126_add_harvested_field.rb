class AddHarvestedField < ActiveRecord::Migration
  def change
    add_column :activity_objects, :harvested, :boolean, :default => false
  end
end