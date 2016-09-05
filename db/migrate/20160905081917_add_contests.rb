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
      t.integer  "mail_list_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    #Contests have and belong to many Actors
    create_table :actors_contests, :id => false do |t|
      t.references :actor, :contest
    end

    create_table "contest_categories" do |t|
      t.integer  "contest_id"
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    #ContestCategories have and belong to many ActivityObjects
    create_table :activity_objects_contest_categories, :id => false do |t|
      t.references :activity_object, :contest_category
    end

  end
end
