class RemoveExcursionTypeFromExcursions < ActiveRecord::Migration
  def up
  	remove_column :excursions, :excursion_type
  end

  def down
  	add_column :excursions, :excursion_type, :string, :default => 'presentation'
  end
end
