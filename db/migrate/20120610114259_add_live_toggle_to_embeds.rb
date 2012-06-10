class AddLiveToggleToEmbeds < ActiveRecord::Migration
  def up
    add_column :embeds, :live, :boolean, :default => 0
  end

  def down
    remove_column :embeds, :live
  end
end
