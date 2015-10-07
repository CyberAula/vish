class AddCompetitionsToVish < ActiveRecord::Migration
    def up
  	add_column :activity_objects, :competition, :boolean, :default => false
  	add_column :actors, :joined_competition, :boolean, :default => false
  end

  def down
  	remove_column :activity_objects, :competition
  	remove_column :actors, :joined_competition
  end
end
