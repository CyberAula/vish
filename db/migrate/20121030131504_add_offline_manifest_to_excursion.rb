class AddOfflineManifestToExcursion < ActiveRecord::Migration
  def up
    add_column :excursions, :offline_manifest, :text
  end

  def down
    remove_column :excursions, :offline_manifest
  end
end
