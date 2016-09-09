class AddContests < ActiveRecord::Migration
  def change
    #Remove old competitions
    if column_exists? :activity_objects, :competition
      remove_column :activity_objects, :competition
    end

    if column_exists? :actors, :joined_competition
      remove_column :actors, :joined_competition
    end

    create_table "contests" do |t|
      t.string "name"
      t.string "template"
      t.string "status", :default => "open"
      t.text "settings", :default => "{}"
      t.boolean "show_in_ui", :default => false
      t.integer  "mail_list_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "contest_enrollments" do |t|
      t.integer  "contest_id"
      t.integer  "actor_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "contest_categories" do |t|
      t.integer  "contest_id"
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "contest_submissions" do |t|
      t.integer  "contest_category_id"
      t.integer  "activity_object_id"
      t.integer  "actor_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end
end
