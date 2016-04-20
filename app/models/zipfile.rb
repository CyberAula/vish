class Zipfile < Document
    
  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/zip.png"
  end

  def as_json(options)
    super.merge!({
      :src => options[:helper].polymorphic_url(self, format: format)
    })
  end

  def fileType
    return Zipfile if self.file.class != Paperclip::Attachment or self.file.path.blank?

    isScorm = false
    isWebapp = false
    Zip::File.open(self.file.path) do |zip|
      isScorm = zip.entries.map{|e| e.name}.include?("imsmanifest.xml")
      isWebapp = zip.entries.map{|e| e.name}.include? "index.html" unless isScorm
    end
    
    return Scormfile if isScorm
    return Webapp if isWebapp
    return Zipfile
  end

  def getResourceAfterSave
    case self.fileType.name
    when Scormfile.name
      resource = Scormfile.createScormfileFromZip(self)
    when Webapp.name
      resource = Webapp.createWebappFromZip(self)
    else
      resource = self
    end
    return resource
  end
  
end