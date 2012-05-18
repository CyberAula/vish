class MakeExcursionThumbnailAString < ActiveRecord::Migration
  def up
    ActivityObject.record_timestamps = false
    Excursion.record_timestamps = false

    add_column :excursions, :thumbnail_url, :string, :default => '/assets/logos/original/excursion-00.png'

    Excursion.all.each do |e|
      e.update_column(:thumbnail_url, "/assets/logos/original/excursion-%{sprintf '%.2i', e.read_attribute(:thumbnail_index)}.png")
    end

    ActivityObject.record_timestamps = true
    Excursion.record_timestamps = true
    Excursion.reset_column_information

    remove_column :excursions, :thumbnail_index
  end

  def down
    remove_column :excursions, :thumbnail_url
    add_column :excursions, :thumbnail_index, :integer, :default => 0
  end
end
