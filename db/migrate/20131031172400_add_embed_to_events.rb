class AddEmbedToEvents < ActiveRecord::Migration
  def up
    add_column :events, :embed, :text
  end

  def down
    remove_column :events, :embed
  end
end
