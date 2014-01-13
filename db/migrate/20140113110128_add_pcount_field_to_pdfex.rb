class AddPcountFieldToPdfex < ActiveRecord::Migration
  def up
  	add_column :pdfexes, :pcount, :integer
  end

  def down
  	remove_column :pdfexes, :pcount
  end
end
