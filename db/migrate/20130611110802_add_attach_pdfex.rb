class AddAttachPdfex < ActiveRecord::Migration
  def up
  	add_column :pdfexes, :attach_file_name,    :string
  	add_column :pdfexes, :attach_content_type, :string
  	add_column :pdfexes, :attach_file_size,    :integer
  	add_column :pdfexes, :attach_updated_at,   :datetime
  end

  def down
  	remove_column :pdfexes, :attach_file_name
    remove_column :pdfexes, :attach_content_type
    remove_column :pdfexes, :attach_file_size
    remove_column :pdfexes, :attach_updated_at
  end
end