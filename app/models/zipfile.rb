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
    if self.file.class != Paperclip::Attachment or self.file.path.blank?
      return Zipfile
    end

    isScorm = false
    isWebapp = false
    Zip::File.open(self.file.path) do |zip|
      isScorm = zip.entries.map{|e| e.name}.include? "imsmanifest.xml"
      unless isScorm
        isWebapp = zip.entries.map{|e| e.name}.include? "index.html"
      end
    end
    
    if isScorm
      return Scormfile
    elsif isWebapp
      return Webapp
    end

    return Zipfile
  end

  def getResourceAfterSave(controller)
    case self.fileType.name
    when Scormfile.name
      resource = Scormfile.createScormfileFromZip(controller,self)
    when Webapp.name
      resource = Webapp.createWebappFromZip(controller,self)
    else
      resource = self
    end
    return resource
  end
  
end