class AddOwnerToPdfexes < ActiveRecord::Migration
  def up
    add_column :pdfexes, :owner_id,	:integer
  end

  def down
    remove_column :pdfexes, :owner_id
  end
end
