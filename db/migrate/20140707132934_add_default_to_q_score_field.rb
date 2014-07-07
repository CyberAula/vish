class AddDefaultToQScoreField < ActiveRecord::Migration
  def change
    change_column :activity_objects, :qscore, :integer, :default => 500000
  end
end
