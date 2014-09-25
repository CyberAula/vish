class WorkshopMigration < ActiveRecord::Migration

  def up
  	create_table "workshops", :force => true do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "workshop_activities", :force => true do |t|
      t.integer  "workshop_id"
      t.integer  "wa_assignment_id"
      t.integer  "wa_gallery_id"
      t.integer  "wa_contributions_gallery_id"
      t.integer  "wa_resource_id"
      t.string   "wa_activity_type"
      t.integer  "position"
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_assignments", :force => true do |t|
      t.integer  "workshop_activity_id"
      t.text     "description"
      t.datetime "open_date"    
      t.datetime "close_date"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "contributions", :force => true do |t|
      t.integer  "activity_object_id"
      t.integer  "wa_assignment_id"
      t.integer  "parent_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_galleries", :force => true do |t|
      t.integer  "workshop_activity_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_gallery_activity_objects", :force => true do |t|
      t.integer  "wa_gallery_id"
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_contributions_galleries", :force => true do |t|
      t.integer  "workshop_activity_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_contributions_gallery_wa_assignments", :force => true do |t|
      t.integer  "wa_contributions_gallery_id"
      t.integer  "wa_assignment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "wa_resources", :force => true do |t|
      t.integer  "workshop_activity_id"
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end

  def down
    drop_table :workshops
    drop_table :workshop_activities
    drop_table :wa_assignments
    drop_table :contributions
    drop_table :wa_galleries
    drop_table :wa_gallery_activity_objects
    drop_table :wa_contributions_galleries
    drop_table :wa_contributions_gallery_wa_assignments
    drop_table :wa_resources
  end
end
