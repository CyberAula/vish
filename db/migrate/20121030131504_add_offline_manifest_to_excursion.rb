class AddOfflineManifestToExcursion < ActiveRecord::Migration
  def up
    add_column :excursions, :offline_manifest, :text, :default => ''
  end

  def down
    remove_column :excursions, :offline_manifest
  end
end
