class AddStreamingToEvents < ActiveRecord::Migration
  def up
    add_column :events, :streaming, :boolean, :default => false
  end

  def down
  	remove_column :events, :streaming
  end

end
