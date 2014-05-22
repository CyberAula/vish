class AddScormsTable < ActiveRecord::Migration
  def up
    create_table "scormfiles", :force => true do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "zipurl"
      t.text     "lourl"
      t.text     "zippath"
      t.text     "lopath"
      t.integer  "width",  :default => 800
      t.integer  "height", :default => 600
    end
  end

  def down
    drop_table "scormfiles"
  end
end
