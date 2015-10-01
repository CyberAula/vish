class AddCompetitionsToVish < ActiveRecord::Migration
    def up
  	add_column :activity_objects, :competition, :boolean, :default => false
  end

  def down
  	remove_attachment :activity_objects, :competition
  end
end
