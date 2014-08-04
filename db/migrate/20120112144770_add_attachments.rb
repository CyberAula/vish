class AddAttachments < ActiveRecord::Migration
  def up
    unless column_exists? :notifications, :attachment
      add_column :notifications, :attachment, :string
    end
  end

  def down
    if column_exists? :notifications, :attachment
      remove_column :notifications, :attachment
    end
  end
end
