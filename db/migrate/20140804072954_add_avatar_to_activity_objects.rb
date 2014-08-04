class AddAvatarToActivityObjects < ActiveRecord::Migration

  def up
    add_column :activity_objects, :avatar_file_name,    :string
    add_column :activity_objects, :avatar_content_type, :string
    add_column :activity_objects, :avatar_file_size,    :integer
    add_column :activity_objects, :avatar_updated_at,   :datetime
  end

  def down
    remove_column :activity_objects, :avatar_file_name
    remove_column :activity_objects, :avatar_content_type
    remove_column :activity_objects, :avatar_file_size
    remove_column :activity_objects, :avatar_updated_at
  end
  
end
