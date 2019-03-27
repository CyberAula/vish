class Imscpfile < ActiveRecord::Base
  before_destroy :remove_files #This callback need to be before has_attached_file, to be executed before paperclip callbacks

  include SocialStream::Models::Object

  has_attached_file :file,
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'

  define_index do
    activity_object_index
  end

  validates_presence_of :title
  validates_presence_of :lohref
  validates_inclusion_of :schema, in: ["IMS Content"], :allow_blank => false, :message => "Invalid IMS CP schema. Only 'IMS Content' schema is supported"
  validates_presence_of :schema, :message => "Invalid IMS CP package. Schema is not defined."
  validates_presence_of :schemaversion, :message => "Invalid IMS CP package. Schema version is not defined."
  before_validation :fill_imscp_version

  def self.getSchemaFromXmlManifest(xmlManifest)
    return nil unless xmlManifest.is_a? Nokogiri::XML::Document
    schemaEl = xmlManifest.at_css('//metadata//schema')
    return schemaEl.text unless schemaEl.nil?
    nil
  end

  def self.getFieldsFromManifest(xmlManifest)
    fields = {}
    fields["schema"] = xmlManifest.at_css('//metadata//schema').text rescue nil
    fields["schemaversion"] = xmlManifest.at_css('//metadata//schemaversion').text rescue nil
    imscp_items = xmlManifest.css('//organizations//organization:first//item')
    imscp_resources = xmlManifest.css('//resources//resource')
    loHrefs = []
    imscp_items.each do |item|
      imscp_resource_id = item.attributes["identifierref"].value rescue nil
      unless imscp_resource_id.blank?
        imscp_resource = imscp_resources.at_css("resource[identifier='" + imscp_resource_id + "']")
        unless imscp_resource.nil? or imscp_resource.attributes.nil? or imscp_resource.attributes["href"].nil? or imscp_resource.attributes["href"].value.blank?
          loHref = {}
          loHref["href"] = imscp_resource.attributes["href"].value
          item_title = item.at_css("title").text rescue nil
          loHref["title"] = item_title unless item_title.blank?
          loHrefs.push(loHref)
        end
      end
    end
    fields["lohref"] = loHrefs.first["href"] unless loHrefs.first.blank?
    fields["lohrefs"] = loHrefs.to_json
    fields
  end

  def self.extract_zip(file,destination)
    FileUtils.mkdir_p(destination)
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(destination,f.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zip_file.extract(f,fpath) unless File.exist?(fpath)
      end
    end
  end

  def self.createImscpfileFromZip(zipfile)
    begin
      resource = Imscpfile.new
      resource.owner_id = zipfile.owner_id
      resource.author_id = zipfile.author_id
      resource.user_author = zipfile.user_author
      resource.created_at = zipfile.created_at
      resource.updated_at = zipfile.updated_at
      resource.activity_object.created_at = zipfile.created_at
      resource.activity_object.updated_at = zipfile.updated_at
      resource.activity_object.scope = zipfile.activity_object.scope
      resource.activity_object.relation_ids = zipfile.activity_object.relation_ids
      resource.activity_object.title = zipfile.activity_object.title
      resource.activity_object.description = zipfile.activity_object.description
      resource.activity_object.age_min = zipfile.activity_object.age_min
      resource.activity_object.age_max = zipfile.activity_object.age_max
      resource.activity_object.language = zipfile.activity_object.language
      resource.activity_object.tag_list = zipfile.activity_object.tag_list
      resource.activity_object.license_id = zipfile.activity_object.license_id
      resource.activity_object.license_attribution = zipfile.activity_object.license_attribution
      resource.activity_object.license_custom = zipfile.activity_object.license_custom
      resource.activity_object.original_author = zipfile.activity_object.original_author
      resource.activity_object.reviewers_qscore = zipfile.reviewers_qscore
      resource.activity_object.users_qscore = zipfile.users_qscore
      #Copy attachment
      resource.file = zipfile.file
      #Copy avatar
      resource.avatar = zipfile.avatar

      # Unpack the IMS CP package into pkgPath and fill the lourl, lopath, zipurl and zippath fields
      zipFilePath = zipfile.file.path
      pkgPath = File.join(File.dirname(zipFilePath), File.basename(zipFilePath,File.extname(zipFilePath)))
      Imscpfile.extract_zip(zipFilePath,pkgPath)

      manifestFilePath = pkgPath + "/imsmanifest.xml"
      if File.exists?(manifestFilePath)
        xmlManifest = File.open(manifestFilePath){ |f| Nokogiri::XML(f) }
        Imscpfile.getFieldsFromManifest(xmlManifest).each do |k,v|
          resource.send(k + "=", v)
        end
      end

      raise "No resource has been found" if pkgPath.nil? or resource.lohref.nil?

      #Save the resource to get its id
      resource.save!

      resource.updateImscpfile(pkgPath)

      #Remove previous ZIP file
      zipfile.destroy

      return resource
    rescue Exception => e
      begin
        #Remove previous ZIP file
        zipfile.destroy
      rescue
      end

      errorMsgMaxLength = 255
      if e.message.length > errorMsgMaxLength
        errorMsg =  e.message[0,errorMsgMaxLength] + "..."
      else
        errorMsg = e.message
      end
      return "Invalid IMS CP package (" + errorMsg + ")"
    end
  end

  def updateImscpfile(pkgPath=nil)

    #Deal with blank pkgPath or undefined mandatory fields
    if pkgPath.blank? or ["schema","schemaversion","lohref", "lohrefs"].select{|f| self.send(f).blank?}.length > 1
      #We need to unpack the IMS CP file
      unless self.file.blank?
        zipFilePath = self.file.path
        pkgPath = File.join(File.dirname(zipFilePath), File.basename(zipFilePath,File.extname(zipFilePath)))
        Imscpfile.extract_zip(zipFilePath,pkgPath)
        manifestFilePath = pkgPath + "/imsmanifest.xml"
        if File.exists?(manifestFilePath)
          xmlManifest = File.open(manifestFilePath){ |f| Nokogiri::XML(f) }
          Imscpfile.getFieldsFromManifest(xmlManifest).each do |k,v|
            self.send(k + "=", v)
          end
        end
      else
        raise "No file has been found. This IMS CP package is corrupted."
      end
    end
    loURLRoot = Vish::Application.config.full_code_domain + "/imscp/packages/" + self.id.to_s

    #Create folders
    if Vish::Application.config.APP_CONFIG["code_path"].nil?
      imscpPackagesDirectoryPath = Rails.root.join('public', 'imscp', 'packages').to_s
    else
      imscpPackagesDirectoryPath = Vish::Application.config.APP_CONFIG["code_path"] + "/imscp/packages"
    end
    loDirectoryPath = imscpPackagesDirectoryPath + "/" + self.id.to_s
    
    require "fileutils"
    FileUtils.mkdir_p(imscpPackagesDirectoryPath)
    FileUtils.rm_rf(loDirectoryPath) if File.exists? loDirectoryPath
    FileUtils.move pkgPath, loDirectoryPath

    #URLs are saved as absolute URLs
    #ZIP paths are always saved as relative paths (the same as the rest of the documents)
    #LO paths are saved as absolute paths when APP_CONFIG["code_path"] is defined
    resourceRelativePath = self.file.path
    resourceRelativePath.slice! Rails.root.to_s

    loDirectoryPathToSave = loDirectoryPath.dup
    loDirectoryPathToSave.slice! Rails.root.to_s if Vish::Application.config.APP_CONFIG["code_path"].nil?

    self.zipurl = Vish::Application.config.full_domain + "/" + self.file.url[1..-1]
    self.zippath = resourceRelativePath
    self.lopath = loDirectoryPathToSave
    self.lourl = loURLRoot + "/vishubcode_imscp_wrapper.html"
    self.loresourceurl = loURLRoot + "/" + self.lohref

    #Generate wrapper HTML (vishubcode_imscp_wrapper.html)
    imscpWrapperFile = DocumentsController.new.render_to_string "show.imscp_wrapper.erb", :locals => {:imscpPackage => self}, :layout => false
    imscpWrapperFilePath = loDirectoryPath + "/vishubcode_imscp_wrapper.html"
    File.open(imscpWrapperFilePath, "w"){|f| f << imscpWrapperFile }

    self.save!
  end

  # Thumbnail file
  def thumb(size, helper)
    "#{ size.to_s }/imscp.png"
  end

  #Overriding mimetype and format methods from SSDocuments

  # The Mime::Type of this document's file
  def mime_type
    Mime::Type.new("application/zip")
  end

  # The type part of the {#mime_type}
  def mime_type_type_sym
    mime_type.to_s.split('/').last.to_sym
  end

  # {#mime_type}'s symbol
  def format
    mime_type.to_sym
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :src => lourl,
     :type => "imscppackage"
    }
  end

  def increment_download_count
    self.activity_object.increment_download_count
  end

  #Return version to show in metadata UI
  def resource_version
    self.schema + " " + self.schemaversion
  end

  def getZipPath
    # ZIP paths are always saved as relative paths (the same as the rest of the documents)
    # return Rails.root.to_s + self.zippath
    self.file.path
  end

  def getLoPath
    #LO paths are saved as relative paths when APP_CONFIG["code_path"] is not defined
    return Rails.root.to_s + self.lopath if Vish::Application.config.APP_CONFIG["code_path"].nil?
    #LO paths are saved as absolute paths when APP_CONFIG["code_path"] is defined
    return self.lopath
  end


  private

  def fill_imscp_version
    if self.schema == "IMS Content" and !self.schemaversion.blank?
        self.imscp_version = self.schemaversion
    end
  end

  def remove_files
    #Remove IMS CP files from the public folder
    require "fileutils"
    FileUtils.rm_rf(self.getLoPath())
  end
  
end
