class RemoveLiveSession < ActiveRecord::Migration
  def up
  	drop_table :live_sessions
  end

  def down
  	create_table :live_sessions do |t|
      t.integer :user_id
      t.integer :excursion_id
      t.timestamps
    end
  end
end

