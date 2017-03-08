class ChangeQscoreDefaults < ActiveRecord::Migration
  def up
    change_column_default :activity_objects, :metadata_qscore, nil
  end

  def down
    change_column_default :activity_objects, :metadata_qscore, nil
  end
end