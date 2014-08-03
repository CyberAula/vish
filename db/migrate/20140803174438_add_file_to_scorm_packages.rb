class AddFileToScormPackages < ActiveRecord::Migration
  def up
    add_column :scormfiles, :file_file_name,    :string
    add_column :scormfiles, :file_content_type, :string
    add_column :scormfiles, :file_file_size,    :integer
    add_column :scormfiles, :file_updated_at,   :datetime
  end

  def down
  	remove_column :scormfiles, :file_file_name
    remove_column :scormfiles, :file_content_type
    remove_column :scormfiles, :attach_file_size
    remove_column :scormfiles, :attach_updated_at
  end
end
