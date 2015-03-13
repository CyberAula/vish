class AddPlainNameToTags < ActiveRecord::Migration
  def up
    add_column :tags, :plain_name, :string
  end

  def down
    remove_column :tags, :plain_name
  end
end
