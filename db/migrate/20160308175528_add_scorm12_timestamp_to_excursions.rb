class AddScorm12TimestampToExcursions < ActiveRecord::Migration  
  def up
  	rename_column :excursions, :scorm_timestamp, :scorm2004_timestamp
    add_column :excursions, :scorm12_timestamp, :timestamp
  end

  def down
    remove_column :excursions, :scorm12_timestamp
    rename_column :excursions, :scorm2004_timestamp, :scorm_timestamp
  end
end