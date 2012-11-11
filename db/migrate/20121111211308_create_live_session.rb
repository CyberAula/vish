class CreateLiveSession < ActiveRecord::Migration
  def up
    create_table :live_sessions do |t|
      t.integer :user_id
      t.integer :excursion_id
      t.timestamps
    end
  end

  def down
    drop_table :live_sessions
  end
end
