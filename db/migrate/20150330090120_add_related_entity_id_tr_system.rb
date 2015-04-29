class AddRelatedEntityIdTrSystem < ActiveRecord::Migration
  def up
  	add_column :tracking_system_entries, :related_entity_id, :integer
  end

  def down
  	remove_column :tracking_system_entries, :related_entity_id
  end
end
