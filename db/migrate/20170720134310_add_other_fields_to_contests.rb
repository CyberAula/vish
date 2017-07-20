class AddOtherFieldsToContests < ActiveRecord::Migration
  def change
    add_column :contests, :other_data, :text
  end
end
