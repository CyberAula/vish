class WorkshopMigration < ActiveRecord::Migration

  def up
    create_table "workshops", :force => true do |t|
      t.integer  "activity_object_id"
      t.boolean "draft", :default => true
      t.timestamps
    end

    create_table "workshop_activities", :force => true do |t|
      t.integer  "workshop_id"

      #Polymorphic
      t.integer  "wa_id"
      t.string   "wa_type"

      #Attrs
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
      t.text     "plaintext"
      t.boolean  "with_dates", :default => false
      t.datetime "open_date"
      t.datetime "due_date"
      t.text "available_contributions"
      t.timestamps
    end

    create_table "contributions", :force => true do |t|
      t.integer  "activity_object_id"
      t.integer  "wa_assignment_id"
      t.integer  "parent_id"
      t.timestamps
    end

    # Text
    create_table "wa_texts", :force => true do |t|
      t.text     "fulltext"
      t.text     "plaintext"
      t.timestamps
    end

    # Contributions Gallery
    create_table "wa_contributions_galleries", :force => true do |t|
      t.timestamps
    end

    create_table "wa_assignments_wa_contributions_galleries", id: false, :force => true do |t|
      t.integer  "wa_assignment_id"
      t.integer  "wa_contributions_gallery_id"
    end

    # Resources Gallery
    create_table "wa_resources_galleries", :force => true do |t|
      t.timestamps
    end

    create_table "activity_objects_wa_resources_galleries", id: false, :force => true do |t|
      t.integer  "activity_object_id"
      t.integer  "wa_resources_gallery_id"
    end

  end

  def down
    drop_table :activity_objects_wa_resources_galleries
    drop_table :wa_resources_galleries
    drop_table :wa_assignments_wa_contributions_galleries
    drop_table :wa_contributions_galleries
    drop_table :wa_texts
    drop_table :contributions
    drop_table :wa_assignments
    drop_table :wa_resources
    drop_table :workshop_activities
    drop_table :workshops
  end
end
