class RenameMveRank < ActiveRecord::Migration
  def up
  	rename_column :actors, :rankMve, :rank_mve
  	rename_column :excursions, :rankMve, :rank_mve
  end

  def down
  	rename_column :actors, :rank_mve, :rankMve
  	rename_column :excursions, :rank_mve, :rankMve
  end
end