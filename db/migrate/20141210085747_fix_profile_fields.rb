class FixProfileFields < ActiveRecord::Migration
  def up
  	change_column :profiles, :description, :text
  end

  def down
  	change_column :profiles, :description, :string
  end
end