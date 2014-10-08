class CreateWritingsTable < ActiveRecord::Migration
  def up
    create_table "writings", :force => true do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "fulltext"
      t.text     "plaintext"
    end
  end

  def down
    drop_table "writings"
  end
end
