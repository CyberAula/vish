class AddFileToWebapps < ActiveRecord::Migration
  def up
    add_column :webapps, :file_file_name,    :string
    add_column :webapps, :file_content_type, :string
    add_column :webapps, :file_file_size,    :integer
    add_column :webapps, :file_updated_at,   :datetime
  end

  def down
  	remove_column :webapps, :file_file_name
    remove_column :webapps, :file_content_type
    remove_column :webapps, :attach_file_size
    remove_column :webapps, :attach_updated_at
  end
end
