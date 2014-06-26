class AddDownloadCountToActivityObject < ActiveRecord::Migration
  def up
    add_column :activity_objects, :download_count, :integer, :default => 0
  end

  def down
    remove_column :activity_objects, :download_count
  end
end