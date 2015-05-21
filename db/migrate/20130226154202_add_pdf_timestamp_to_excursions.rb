class AddPdfTimestampToExcursions < ActiveRecord::Migration
  def up
    add_column :excursions, :pdf_timestamp, :timestamp
  end

  def down
    remove_column :excursions, :pdf_timestamp
  end
end
