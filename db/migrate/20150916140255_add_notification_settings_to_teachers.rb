class AddNotificationSettingsToTeachers < ActiveRecord::Migration
  def up
  	add_column :private_student_groups, :teacher_notification, :string, default: "ALL", nil: false
  end

  def down
  	remove_column :private_student_groups, :teacher_notification
  end
end
