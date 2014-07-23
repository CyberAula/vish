class AddActivityObjectLengths < ActiveRecord::Migration
  def up
    add_column :activity_objects, :title_length, :integer, :default => 1
    add_column :activity_objects, :desc_length, :integer, :default => 1
    add_column :activity_objects, :tags_length, :integer, :default => 1
  end

  def down
    remove_column :activity_objects, :title_length
    remove_column :activity_objects, :desc_length
    remove_column :activity_objects, :tags_length
  end
end
