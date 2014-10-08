class WorkshopMigration < ActiveRecord::Migration

  def up
    create_table "workshops", :force => true do |t|
      t.integer  "activity_object_id"
      t.timestamps
    end

    create_table "workshop_activities", :force => true do |t|
      t.integer  "workshop_id"
      t.string   "wa_activity_type"
      t.integer  "position"
      t.string   "title"
      t.text     "description"
      t.timestamps
    end

    #Types of Workshop Activities

    # Resource
    create_table "wa_resources", :force => true do |t|
      t.integer  "activity_object_id"
      t.timestamps
    end

    # Assignment
    create_table "wa_assignments", :force => true do |t|
      t.text     "fulltext"
      t.datetime "open_date"
      t.datetime "due_date"
      t.timestamps
    end

    create_table "contributions", :force => true do |t|
      t.integer  "activity_object_id"
      t.integer  "wa_assignment_id"
      t.integer  "parent_id"
      t.timestamps
    end

    # Contributions Gallery
    create_table "wa_contributions_galleries", :force => true do |t|
      t.timestamps
    end

    create_table "wa_contributions_gallery_wa_assignments", id: false, :force => true do |t|
      t.integer  "wa_contributions_gallery_id"
      t.integer  "wa_assignment_id"
      t.timestamps
    end

    # Resources Gallery
    create_table "wa_galleries", :force => true do |t|
      t.timestamps
    end

    create_table "wa_gallery_activity_objects", id: false, :force => true do |t|
      t.integer  "wa_gallery_id"
      t.integer  "activity_object_id"
      t.timestamps
    end

  end

  def down
    drop_table :workshops
    drop_table :workshop_activities
    drop_table :wa_resources
    drop_table :wa_assignments
    drop_table :contributions
    drop_table :wa_contributions_galleries
    drop_table :wa_contributions_gallery_wa_assignments
    drop_table :wa_galleries
    drop_table :wa_gallery_activity_objects
  end
end
