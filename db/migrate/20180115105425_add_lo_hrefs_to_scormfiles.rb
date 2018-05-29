class AddLoHrefsToScormfiles < ActiveRecord::Migration
  def change
    add_column :scormfiles, :lohrefs, :text
  end
end