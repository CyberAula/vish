class ConvertToOfficeDocument < ActiveRecord::Migration
  def up
    Document.all.each do |doc|
      if !(doc.file_content_type =~ /^application.*vnd.oasis.*/).nil? or
         !(doc.file_content_type =~ /^application.*vnd.openxmlformats-officedocument.*/).nil? or
         !(doc.file_content_type =~ /^application.*pdf/).nil? or
         !(doc.file_content_type =~ /^application.*vnd.ms-excel/).nil? or
         !(doc.file_content_type =~ /^application.*vnd.ms-word/).nil? or
         !(doc.file_content_type =~ /^application.*vnd.ms-powerpoint/).nil?
        doc.type="OfficeDocument"
        doc.save!
      end
    end
  end

  def down
    OfficeDocument.all.each do |od|
      od.type=nil
      od.save!
    end
  end
end
