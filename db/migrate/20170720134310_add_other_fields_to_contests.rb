class AddOtherFieldsToContests < ActiveRecord::Migration
  def change
    add_column :contests, :other_data, :text, :array => true
  	add_column :contest_enrollments, :other_data, :text, :default => "{}"
  end

end
