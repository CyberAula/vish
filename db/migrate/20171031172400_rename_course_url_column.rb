class RenameCourseUrlColumn < ActiveRecord::Migration
  def up
    rename_column :courses, :url, :moodle_url
  end

  def down
    rename_column :courses, :moodle_url, :url
  end
end
