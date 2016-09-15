class AddMailLists < ActiveRecord::Migration
  def change
  	create_table "mail_lists" do |t|
      t.string "name"
      t.text "settings", :default => "{}"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "mail_list_items" do |t|
      t.integer  "mail_list_id"
      t.integer  "actor_id"
      t.string   "email"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
