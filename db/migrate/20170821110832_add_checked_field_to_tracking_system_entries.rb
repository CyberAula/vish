class AddCheckedFieldToTrackingSystemEntries < ActiveRecord::Migration
  def change
    add_column :tracking_system_entries, :checked, :boolean, :default => false
  end
end