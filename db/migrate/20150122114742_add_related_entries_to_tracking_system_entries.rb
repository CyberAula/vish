class AddRelatedEntriesToTrackingSystemEntries < ActiveRecord::Migration
  def up
    add_column :tracking_system_entries, :tracking_system_entry_id, :integer
  end

  def down
    remove_column :tracking_system_entries, :tracking_system_entry_id
  end
end
