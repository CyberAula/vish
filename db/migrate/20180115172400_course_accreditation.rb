class CourseAccreditation < ActiveRecord::Migration
  def change
    add_column :courses, :accredited, :boolean, :default => false
    add_column :courses, :accredited_text, :text
    add_column :courses, :accredited_logo, :text
    add_column :courses, :self_learning_format, :boolean, :default => false
    add_column :courses, :duration_text, :text    
  end
end
