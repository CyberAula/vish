class AddOccupationField < ActiveRecord::Migration
  def up
  	change_table "profiles" do |t|
      t.integer "occupation", :default => nil
    end
  end

  def down
  	 change_table "profiles" do |t|
      t.remove "occupation"
    end
  end
end
