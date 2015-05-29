class AddLicenses < ActiveRecord::Migration
	def up
		create_table :licenses do |t|
			t.string :key
			t.timestamps
		end
		add_column :activity_objects, :license_id, :integer
	end

	def down
		remove_column :activity_objects, :license_id
		drop_table :licenses
	end
end
