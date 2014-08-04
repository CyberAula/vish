class AddTypeToExcursions < ActiveRecord::Migration
  def up
    add_column :excursions, :excursion_type, :string, :default => 'presentation'
  end

  def down
    remove_column :excursions, :excursion_type
  end
end
