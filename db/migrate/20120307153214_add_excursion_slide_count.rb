class AddExcursionSlideCount < ActiveRecord::Migration
  def up
    change_table :excursions do |t|
      t.integer "slide_count", :default => 1
    end
  end

  def down
    change_table :excursions do |t|
      t.remove "slide_count"
    end
  end
end
