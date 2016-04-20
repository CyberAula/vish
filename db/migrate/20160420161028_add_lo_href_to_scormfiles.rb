class AddLoHrefToScormfiles < ActiveRecord::Migration
  def change
    add_column :scormfiles, :lohref, :string
    add_column :scormfiles, :loresourceurl, :string
  end
end