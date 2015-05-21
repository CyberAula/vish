class CreateTrackingSystem < ActiveRecord::Migration
  def up
  	create_table :tracking_system_entries do |t|
      t.string  :app_id
      t.text    :data
      t.timestamps
    end
  end

  def down
  	drop_table :tracking_system_entries
  end
end
