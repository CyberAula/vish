class UpdateThumbnailUrlToText < ActiveRecord::Migration
  def up
  	change_column :excursions, :thumbnail_url, :text, :default => nil
  	#change the default to nil because text can't have a default value
  end

  def down
  	# This causes trouble if you have strings longer
    # than 255 characters.
  	change_column :excursions, :thumbnail_url, :string
  end
end
