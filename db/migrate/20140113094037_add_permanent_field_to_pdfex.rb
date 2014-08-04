class AddPermanentFieldToPdfex < ActiveRecord::Migration
  def up
  	add_column :pdfexes, :permanent, :boolean, :default => false
  end

  def down
  	remove_column :pdfexes, :permanent	
  end
end
