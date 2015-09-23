class AddNotificationSettingsToTeachers < ActiveRecord::Migration
  def up
  	add_column :private_student_groups, :teacher_notification, :string, default: "ALL", nil: false
  	add_column :excursions, :notified_teacher, :boolean, :default => :false
  end

  def down
  	remove_column :private_student_groups, :teacher_notification
  	remove_column :excursions, :notified_teacher
  end
end
