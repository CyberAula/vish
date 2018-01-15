class CourseAccreditation < ActiveRecord::Migration
  def change
    add_column :courses, :accredited, :boolean, :default => false
    add_column :courses, :accredited_text, :text
    add_column :courses, :accredited_logo, :text
  end
end
