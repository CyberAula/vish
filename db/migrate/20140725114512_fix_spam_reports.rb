class FixSpamReports < ActiveRecord::Migration
  def up
  	rename_column :spam_reports, :reporter_user_id, :reporter_actor_id
  	change_column :spam_reports, :issue, :text
  	add_column :spam_reports, :pending, :boolean, :default => true
  end

  def down
  	rename_column :spam_reports, :reporter_actor_id, :reporter_user_id
  	change_column :spam_reports, :issue, :string
  	remove_column :spam_reports, :pending
  end
end
