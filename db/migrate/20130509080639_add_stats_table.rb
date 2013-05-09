class AddStatsTable < ActiveRecord::Migration
  def up
  	create_table :stats do |t|
      t.string	:stat_name, :null => false 
      t.integer :stat_value, :default=>0
    end
  end

  def down
  	drop_table :stats
  end
end
