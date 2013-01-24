class AddScormTimestampToExcursions < ActiveRecord::Migration  
  def up
    add_column :excursions, :scorm_timestamp, :timestamp
  end

  def down
    remove_column :excursions, :scorm_timestamp
  end

end
