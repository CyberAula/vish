class AddPermissionsToActivityObjects < ActiveRecord::Migration
	def up
		add_column :activity_objects, :allow_download, :boolean, :default => true
		add_column :activity_objects, :allow_comment, :boolean, :default => true
		add_column :activity_objects, :allow_clone, :boolean, :default => true
	end

	def down
		remove_column :activity_objects, :allow_download
		remove_column :activity_objects, :allow_comment
		remove_column :activity_objects, :allow_clone
	end
end
