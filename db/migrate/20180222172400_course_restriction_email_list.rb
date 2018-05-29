class CourseRestrictionEmailList < ActiveRecord::Migration
  def change
    add_column :courses, :restriction_email_list, :text    
  end
end
