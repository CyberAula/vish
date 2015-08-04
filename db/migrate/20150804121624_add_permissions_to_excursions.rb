class AddPermissionsToExcursions < ActiveRecord::Migration
	def up
		add_column :excursions, :allow_download, :boolean, :default => true
		add_column :excursions, :allow_comment, :boolean, :default => true
		add_column :excursions, :allow_clone, :boolean, :default => true
	end

	def down
		remove_column :excursions, :allow_download
		remove_column :excursions, :allow_comment
		remove_column :excursions, :allow_clone
	end
end
