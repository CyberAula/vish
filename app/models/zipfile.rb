class Zipfile < Document
    
  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/zip.png"
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :src => options[:helper].polymorphic_url(self, format: format),
     :type => "Zipfile"
    }
  end

  def fileType
    return "Zipfile" if self.file.class != Paperclip::Attachment or self.file.path.blank?

    fileType = "Zipfile"
    Zip::File.open(self.file.path) do |zip|
      manifest = zip.entries.select{|e| e.name == "imsmanifest.xml"}.first
      if manifest
        schema = Imscpfile.getSchemaFromXmlManifest(Nokogiri::XML(manifest.get_input_stream.read)) rescue "invalid schema"
        case schema
        when "IMS Content"
          fileType = "Imscpfile"
        when "ADL SCORM", nil
          fileType = "Scormfile"
        end
      else
        index = zip.entries.select{|e| e.name == "index.html"}.first
        fileType = "Webapp" if index
      end
    end

    return fileType
  end

  def getResourceAfterSave
    case self.fileType
    when "Scormfile"
      resource = Scormfile.createScormfileFromZip(self)
    when "Imscpfile"
      resource = Imscpfile.createImscpfileFromZip(self)
    when "Webapp"
      resource = Webapp.createWebappFromZip(self)
    else
      resource = self
    end
    return resource
  end
  
end