class AddTagArrayText < ActiveRecord::Migration
  def up
  	add_column :activity_objects, :tag_array_text, :text, :default => ""
  end

  def down
  	remove_column :activity_objects, :tag_array_text
  end
end
