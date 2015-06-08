class AddOriginalAuthorToAOs < ActiveRecord::Migration
	def up
		add_column :activity_objects, :original_author, :text
		add_column :activity_objects, :license_attribution, :text
	end

	def down
		remove_column :activity_objects, :original_author
		remove_column :activity_objects, :license_attribution, :text
	end
end
