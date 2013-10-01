class AddSpamTable < ActiveRecord::Migration
  def up
  	create_table :spam_reports do |t|
  	  t.integer "activity_object_id"
  	  t.integer "reporter_user_id"
  	  t.string "issue"
  	  t.integer "report_value"
      t.timestamps
    end
  end

  def down
  	drop_table :spam_reports
  end
end
