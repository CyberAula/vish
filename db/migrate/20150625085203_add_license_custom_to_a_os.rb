class AddLicenseCustomToAOs < ActiveRecord::Migration
	def up
		add_column :activity_objects, :license_custom, :text
	end

	def down
		remove_column :activity_objects, :license_custom, :text
	end
end
