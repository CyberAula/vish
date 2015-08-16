class AddPermissionsAndRequests < ActiveRecord::Migration
  def up
    create_table :service_permissions do |t|
      t.integer :owner_id
      t.string :key
      t.timestamps
    end
    create_table :service_requests do |t|
      t.integer :owner_id
      t.string :status, :default => "Pending"
      t.string :type
      t.text :description
      t.attachment :attachment
      t.timestamps
    end
  end

  def down
    drop_table :service_requests
    drop_table :service_permissions
  end
end
