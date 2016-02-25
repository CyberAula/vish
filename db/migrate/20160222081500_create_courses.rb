class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table "courses", :force => true do |t|
      t.integer     "activity_object_id"
      t.timestamps  null: false
      t.date        "start_date"
      t.date        "end_date"
      t.boolean     "closed", :default => false
      t.boolean     "restricted", :default => false
      t.string      "restriction_email"
      t.string      "restriction_password"
      t.string      "url"
      t.string      "course_password"
      t.attachment  "attachment"
    end
    create_table :courses_users, id: false do |t|
      t.belongs_to :user, index: true
      t.belongs_to :course, index: true
    end
  end

  def down
    drop_table "courses"
    drop_table "courses_users"
  end
end