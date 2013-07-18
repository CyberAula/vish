class CreatePdfexes < ActiveRecord::Migration
  def change
    create_table :pdfexes do |t|
      t.timestamps
    end
  end
end
