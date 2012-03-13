class AddExcursionThumbnailIndex < ActiveRecord::Migration
  def up
    change_table :excursions do |t|
      t.integer :thumbnail_index, :default => 0
    end
  end

  def down
    change_table :excursions do |t|
      t.remove :thumbnail_index
    end
  end
end
