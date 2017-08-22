class RemoveFieldsFromLoInteraction < ActiveRecord::Migration
  def up
    remove_column :lo_interactions, :x1n
    remove_column :lo_interactions, :x2n
    remove_column :lo_interactions, :x3n
    remove_column :lo_interactions, :interaction_qscore
    remove_column :lo_interactions, :qscore
  end

  def down
  end
end