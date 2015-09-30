class AddBannerToWorkshop < ActiveRecord::Migration
  def up
  	add_attachment :workshops, :banner
  end

  def down
  	remove_attachment :workshops, :banner
  end
end