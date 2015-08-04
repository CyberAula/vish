class AddMetadataScoreToAos < ActiveRecord::Migration
  def up
    add_column :activity_objects, :metadata_qscore, :decimal, :precision => 12, :scale => 6, :default => 0
  end

  def down
    remove_column :activity_objects, :metadata_qscore
  end
end
