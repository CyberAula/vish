class AddLiveToggleToEmbeds < ActiveRecord::Migration
  def up
    add_column :embeds, :live, :boolean, :default => false
  end

  def down
    remove_column :embeds, :live
  end
end
