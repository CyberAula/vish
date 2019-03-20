require 'builder'

class Excursion < ActiveRecord::Base
 
  attr_accessor :attachment_url
  has_attached_file :attachment, 
                    :url => '/:class/:id/attachment_file',
                    :path => ':rails_root/documents/attachments/:id_partition/:filename.:extension'
  validates_attachment_size :attachment, :less_than => 8.megabytes

  include SocialStream::Models::Object
  has_many :excursion_contributors, :dependent => :destroy
  has_many :contributors, :class_name => "Actor", :through => :excursion_contributors


  validates_presence_of :json
  before_validation :fill_license
  after_save :parse_for_meta
  after_save :fix_post_activity_nil
  # after_save :send_to_loep
  after_destroy :remove_scorms
  after_destroy :remove_pdf

  define_index do
    activity_object_index
    
    has slide_count
    has draft
  end



  ####################
  ## Model methods
  ####################

  def to_json(options=nil)
    json
  end

  def to_ediphy
    require 've_to_ediphy'
    VETOEDIPHY.translate(json)
  end

  ####################
  ## OAI-PMH Management
  ####################
  def oai_dc_identifier
    Rails.application.routes.url_helpers.excursion_url(:id => self.id)
  end

  def oai_dc_title
    title
  end

  def oai_dc_description
    description
  end

  def oai_dc_creator
    author.name
  end

  def to_oai_lom
    identifier = Rails.application.routes.url_helpers.excursion_url(:id => self.id)
    xmlMetadata = ::Builder::XmlMarkup.new(:indent => 2)
    Excursion.generate_LOM_metadata(JSON(self.json),self,{LOMschema: "ODS", :target => xmlMetadata, :id => identifier})
    xmlMetadata
  end



  ####################
  ## SCORM Management
  ####################

  def self.scormFolderPath(version)
    return "#{Rails.root}/public/scorm/" + version + "/excursions/"
  end

  def scormFilePath(version)
    Excursion.scormFolderPath(version) + "#{self.id}.zip"
  end

  def to_scorm(controller,version="2004")
    if self.scorm_needs_generate(version)
      folderPath = Excursion.scormFolderPath(version)
      fileName = self.id
      json = JSON(self.json)
      Excursion.createSCORM(version,folderPath,fileName,json,self,controller)
      self.update_column(((version=="12") ? :scorm12_timestamp : :scorm2004_timestamp), Time.now)
    end
  end

  def scorm_needs_generate(version="2004")
    scormTimestam = (version=="12") ? self.scorm12_timestamp : self.scorm2004_timestamp
    scormTimestam.nil? or self.updated_at > scormTimestam or !File.exist?(self.scormFilePath(version))
  end

  def remove_scorms
    ["12","2004"].each do |scormVersion|
      scormFilePath = scormFilePath(scormVersion)
      File.delete(scormFilePath) if File.exist?(scormFilePath)
    end
  end

  def self.createSCORM(version="2004",folderPath,fileName,json,excursion,controller)
    require 'zip'

    # folderPath = "#{Rails.root}/public/scorm/version/excursions/"
    # fileName = self.id
    # json = JSON(self.json)
    t = File.open("#{folderPath}#{fileName}.zip", 'w')

    #Add manifest, main HTML file and additional files
    Zip::OutputStream.open(t.path) do |zos|
      xml_manifest = Excursion.generate_scorm_manifest(version,json,excursion)
      zos.put_next_entry("imsmanifest.xml")
      zos.print xml_manifest.target!()

      zos.put_next_entry("excursion.html")
      zos.print controller.render_to_string "show.scorm.erb", :locals => {:excursion=>excursion, :json => json}, :layout => false  
    end

    #Add required XSD files and folders
    schemaDirs = []
    schemaFiles = []
    #SCORM schema
    schemaDirs.push("#{Rails.root}/public/schemas/SCORM_" + version)
    #LOM schema
    # schemaDirs.push("#{Rails.root}/public/schemas/lom")
    schemaFiles.push("#{Rails.root}/public/schemas/lom/lom.xsd");
    
    schemaDirs.each do |dir|
      zip_folder(t.path,dir)
    end

    if schemaFiles.length > 0
      Zip::File.open(t.path, Zip::File::CREATE) { |zipfile|
        schemaFiles.each do |filePath|
          zipfile.add(File.basename(filePath),filePath)
        end
      }
    end

    #Copy SCORM assets (image, javascript and css files)
    dir = "#{Rails.root}/lib/plugins/vish_editor/app/scorm"
    zip_folder(t.path,dir)

    #Add theme
    themesPath = "#{Rails.root}/lib/plugins/vish_editor/app/assets/images/themes/"
    theme = "theme1" #Default theme
    if json["theme"] and File.exists?(themesPath + json["theme"])
      theme = json["theme"]
    end
    #Copy excursion theme
    zip_folder(t.path,"#{Rails.root}/lib/plugins/vish_editor/app/assets",themesPath + theme)

    t.close
  end

  def self.zip_folder(zipFilePath,root,dir=nil)
    dir = root unless dir

    folderNames = []
    fileNames = []
    Dir.entries(dir).reject{|i| i.start_with?(".")}.each do |itemName|
      itemPath = "#{dir}/#{itemName}"
      if File.directory?(itemPath)
        folderNames << itemName
      elsif File.file?(itemPath)
        fileNames << itemName
      end
    end

    #Subdirectories
    folderNames.each do |subFolderName|
      zip_folder(zipFilePath,root,"#{dir}/#{subFolderName}")
    end

    #Files
    if fileNames.length > 0
      Zip::File.open(zipFilePath, Zip::File::CREATE) { |zipfile|
        fileNames.each do |fileName|
          filePathInZip = String.new("#{dir}/#{fileName}").sub(root + "/","")
          zipfile.add(filePathInZip,"#{dir}/#{fileName}")
        end
      }
    end
  end

  def self.generate_scorm_manifest(version,ejson,excursion,options={})
    version = "2004" unless version.is_a? String and ["12","2004"].include?(version)

    #Get manifest resource identifier and LOM identifier
    if excursion and !excursion.id.nil?
      identifier = excursion.id.to_s
      lomIdentifier = Rails.application.routes.url_helpers.excursion_url(:id => excursion.id)
    elsif (ejson["vishMetadata"] and ejson["vishMetadata"]["id"])
      identifier = ejson["vishMetadata"]["id"].to_s
      lomIdentifier = "urn:ViSH:" + identifier
    else
      count = Site.current.config["tmpCounter"].nil? ? 1 : Site.current.config["tmpCounter"]
      Site.current.config["tmpCounter"] = count + 1
      Site.current.save!
      
      identifier = "TmpSCORM_" + count.to_s
      lomIdentifier = "urn:ViSH:" + identifier
    end

    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"


     #Select LOM Header options
    manifestHeaderOptions = {}
    manifestContent = {}

    case version
    when "12"
      #SCORM 1.2
      manifestHeaderOptions = {
        "identifier"=>"VISH_PRESENTATION_" + identifier,
        "version"=>"1.0",
        "xmlns"=>"http://www.imsproject.org/xsd/imscp_rootv1p1p2",
        "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_rootv1p2",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.imsproject.org/xsd/imscp_rootv1p1p2 imscp_rootv1p1p2.xsd http://www.imsglobal.org/xsd/imsmd_rootv1p2p1 imsmd_rootv1p2p1.xsd http://www.adlnet.org/xsd/adlcp_rootv1p2 adlcp_rootv1p2.xsd"
      }
      manifestContent["schemaVersion"] = "1.2"
    when "2004"
      #SCORM 2004 4th Edition
      manifestHeaderOptions =  { 
        "identifier"=>"VISH_PRESENTATION_" + identifier,
        "version"=>"1.3",
        "xmlns"=>"http://www.imsglobal.org/xsd/imscp_v1p1",
        "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_v1p3",
        "xmlns:adlseq"=>"http://www.adlnet.org/xsd/adlseq_v1p3",
        "xmlns:adlnav"=>"http://www.adlnet.org/xsd/adlnav_v1p3",
        "xmlns:imsss"=>"http://www.imsglobal.org/xsd/imsss",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd"
      }
      manifestContent["schemaVersion"] = "2004 4th Edition"
    else
      #Future SCORM versions
    end

    myxml.manifest(manifestHeaderOptions) do

      myxml.metadata do
        myxml.schema("ADL SCORM")
        myxml.schemaversion(manifestContent["schemaVersion"])
        #Add LOM metadata
        Excursion.generate_LOM_metadata(ejson,excursion,{:target => myxml, :id => lomIdentifier, :LOMschema => (options[:LOMschema]) ? options[:LOMschema] : "custom", :scormVersion => version})
      end

      myxml.organizations('default'=>"defaultOrganization") do
        myxml.organization('identifier'=>"defaultOrganization") do
          if ejson["title"]
            myxml.title(ejson["title"])
          else
            myxml.title("Untitled")
          end
          itemOptions = {
            'identifier'=>"PRESENTATION_" + identifier,
            'identifierref'=>"PRESENTATION_" + identifier + "_RESOURCE"
          }
          if version == "12"
            itemOptions["isvisible"] = "true"
          end
          myxml.item(itemOptions) do
            if ejson["title"]
              myxml.title(ejson["title"])
            else
              myxml.title("Untitled")
            end
            if version == "12"
              myxml.tag!("adlcp:masteryscore") do
                myxml.text!("50")
              end
            end
          end
        end
      end

      resourceOptions = {
        'identifier'=>"PRESENTATION_" + identifier + "_RESOURCE",
        'type'=>"webcontent",
        'href'=>"excursion.html",
      }
      if version == "12"
        resourceOptions['adlcp:scormtype'] = "sco"
      else
        resourceOptions['adlcp:scormType'] = "sco"
      end

      myxml.resources do         
        myxml.resource(resourceOptions) do
          myxml.file('href'=> "excursion.html")
        end
      end

    end    

    return myxml
  end

  def self.createSCORMForGroup(version="2004",folderPath,fileName,excursions,controller,options)
    require 'zip'
    t = File.open("#{folderPath}#{fileName}.zip", 'w')

    themes = ["theme1"]

    #Add manifest, main HTML file and additional files
    Zip::OutputStream.open(t.path) do |zos|
      xml_manifest = Excursion.generate_scorm_manifest_for_group(version,excursions,options)
      zos.put_next_entry("imsmanifest.xml")
      zos.print xml_manifest.target!()
      excursions.each do |ex|
        ex_json = JSON.parse(ex.json)
        themes.push(ex_json["theme"])
        zos.put_next_entry("excursion-" + ex.id.to_s + ".html")
        zos.print controller.render_to_string "excursions/show.scorm.erb", :locals => {:excursion=>ex, :json => ex_json, :options => options}, :layout => false
      end
    end

    #Add required XSD files and folders
    schemaDirs = []
    schemaFiles = []
    #SCORM schema
    schemaDirs.push("#{Rails.root}/public/schemas/SCORM_" + version)
    #LOM schema
    # schemaDirs.push("#{Rails.root}/public/schemas/lom")
    schemaFiles.push("#{Rails.root}/public/schemas/lom/lom.xsd");
    
    schemaDirs.each do |dir|
      zip_folder(t.path,dir)
    end

    if schemaFiles.length > 0
      Zip::File.open(t.path, Zip::File::CREATE) { |zipfile|
        schemaFiles.each do |filePath|
          zipfile.add(File.basename(filePath),filePath)
        end
      }
    end

    #Copy SCORM assets (image, javascript and css files)
    dir = "#{Rails.root}/lib/plugins/vish_editor/app/scorm"
    zip_folder(t.path,dir)

    #Add themes
    themesPath = "#{Rails.root}/lib/plugins/vish_editor/app/assets/images/themes/"
    themes.compact.uniq.each do |theme|
      zip_folder(t.path,"#{Rails.root}/lib/plugins/vish_editor/app/assets",themesPath + theme) if File.exists?(themesPath + theme)
    end

    t.close
  end

  def self.generate_scorm_manifest_for_group(version,excursions,options={})
    version = "2004" unless version.is_a? String and ["12","2004"].include?(version)

    #Get manifest resource identifier and LOM identifier
    if options[:category]
      identifier = "Category-" + options[:category].id.to_s
      lomIdentifier = "urn:ViSH:" + identifier
      title = options[:category].title
    else
      count = Site.current.config["tmpCounter"].nil? ? 1 : Site.current.config["tmpCounter"]
      Site.current.config["tmpCounter"] = count + 1
      Site.current.save!
      identifier = "TmpSCORM_" + count.to_s
      lomIdentifier = "urn:ViSH:" + identifier
      title = "Untitled"
    end
    
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    #Select LOM Header options
    manifestHeaderOptions = {}
    manifestContent = {}

    case version
    when "12"
      #SCORM 1.2
      manifestHeaderOptions = {
        "identifier"=>"VISH_PRESENTATION_GROUP_" + identifier,
        "version"=>"1.0",
        "xmlns"=>"http://www.imsproject.org/xsd/imscp_rootv1p1p2",
        "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_rootv1p2",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.imsproject.org/xsd/imscp_rootv1p1p2 imscp_rootv1p1p2.xsd http://www.imsglobal.org/xsd/imsmd_rootv1p2p1 imsmd_rootv1p2p1.xsd http://www.adlnet.org/xsd/adlcp_rootv1p2 adlcp_rootv1p2.xsd"
      }
      manifestContent["schemaVersion"] = "1.2"
    when "2004"
      #SCORM 2004 4th Edition
      manifestHeaderOptions =  { 
        "identifier"=>"VISH_PRESENTATION_GROUP_" + identifier,
        "version"=>"1.3",
        "xmlns"=>"http://www.imsglobal.org/xsd/imscp_v1p1",
        "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_v1p3",
        "xmlns:adlseq"=>"http://www.adlnet.org/xsd/adlseq_v1p3",
        "xmlns:adlnav"=>"http://www.adlnet.org/xsd/adlnav_v1p3",
        "xmlns:imsss"=>"http://www.imsglobal.org/xsd/imsss",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd"
      }
      manifestContent["schemaVersion"] = "2004 4th Edition"
    else
      #Future SCORM versions
    end

    myxml.manifest(manifestHeaderOptions) do

      myxml.metadata do
        myxml.schema("ADL SCORM")
        myxml.schemaversion(manifestContent["schemaVersion"])
        #TODO: add LOM metadata
      end

      myxml.organizations('default'=>"defaultOrganization") do
        myxml.organization('identifier'=>"defaultOrganization") do
          myxml.title(title)

          excursions.each do |ex|
            itemOptions = {
              'identifier'=>"PRESENTATION_GROUP_" + ex.id.to_s,
              'identifierref'=>"PRESENTATION_GROUP_" + ex.id.to_s + "_RESOURCE"
            }
            if version == "12"
              itemOptions["isvisible"] = "true"
            end
            myxml.item(itemOptions) do
              myxml.title(ex.title || "Untitled")
              if version == "12"
                myxml.tag!("adlcp:masteryscore") do
                  myxml.text!("50")
                end
              end
            end
          end
        end
      end

      myxml.resources do
        excursions.each do |ex|
          resourceOptions = {
            'identifier'=>"PRESENTATION_GROUP_" + ex.id.to_s + "_RESOURCE",
            'type'=>"webcontent",
            'href'=>"excursion-" + ex.id.to_s + ".html",
          }
          if version == "12"
            resourceOptions['adlcp:scormtype'] = "sco"
          else
            resourceOptions['adlcp:scormType'] = "sco"
          end
          myxml.resource(resourceOptions) do
            myxml.file('href'=> "excursion-" + ex.id.to_s + ".html")
          end
        end
      end
    end    

    return myxml
  end


  ####################
  ## LOM Metadata
  ####################

  # Metadata based on LOM (Learning Object Metadata) standard
  # LOM final draft: http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf
  def self.generate_LOM_metadata(ejson, excursion, options={})
    _LOMschema = "custom"

    supportedLOMSchemas = ["custom","loose","ODS","ViSH"]
    if supportedLOMSchemas.include? options[:LOMschema]
      _LOMschema = options[:LOMschema]
    end

    if options[:target]
      myxml = ::Builder::XmlMarkup.new(:indent => 2, :target => options[:target])
    else
      myxml = ::Builder::XmlMarkup.new(:indent => 2)
      myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    end
   
    #Select LOM Header options
    lomHeaderOptions = {}

    case _LOMschema
    when "loose","custom"
      lomHeaderOptions =  { 'xmlns' => "http://ltsc.ieee.org/xsd/LOM",
                            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                            'xsi:schemaLocation' => "http://ltsc.ieee.org/xsd/LOM lom.xsd"
                          }
    when "ODS"
      lomHeaderOptions =  { 'xmlns' => "http://ltsc.ieee.org/xsd/LOM",
                            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                            'xsi:schemaLocation' => "http://ltsc.ieee.org/xsd/LOM lomODS.xsd"
                          }
    else
      #Extension not supported/recognized
      lomHeaderOptions = {}
    end


    myxml.tag!("lom",lomHeaderOptions) do

      #Calculate some recurrent vars

      #Identifier
      loIdIsURI = false
      loIdIsURN = false
      loId = nil

      if options[:id]
          loId = options[:id].to_s

          begin
            loUri = URI.parse(loId)
            if %w( http https ).include?(loUri.scheme)
              loIdIsURI = true
            elsif %w( urn ).include?(loUri.scheme)
              loIdIsURN = true
            end
          rescue
          end

          if !loIdIsURI and !loIdIsURN
            #Build URN
            loId = "urn:ViSH:"+loId
          end
      end

      #Excursion instance
      excursionInstance = nil
      if excursion
        excursionInstance = excursion
      elsif ejson["vishMetadata"] and ejson["vishMetadata"]["id"]
        excursionInstance = Excursion.find_by_id(ejson["vishMetadata"]["id"])
        excursionInstance = nil unless excursionInstance.public?
      end

      #Location
      loLocation = nil
      unless excursionInstance.nil?
        loLocation = Rails.application.routes.url_helpers.excursion_url(:id => excursionInstance.id) if excursionInstance.draft == false
      end

      #Language (LO language and metadata language)
      loLanguage = Lom.getLoLanguage(ejson["language"], _LOMschema)
      if loLanguage.nil?
        loLanOpts = {}
      else
        loLanOpts = { :language=> loLanguage }
      end
      metadataLanguage = "en"

      #Author name
      authorName = nil
      if ejson["author"] and ejson["author"]["name"]
        authorName = ejson["author"]["name"]
      elsif (!excursion.nil? and !excursion.author.nil? and !excursion.author.name.nil?)
        authorName = excursion.author.name
      end

      # loDate 
      # According to ISO 8601 (e.g. 2014-06-23)
      if excursion
        loDate = excursion.updated_at
      else
        loDate = Time.now
      end
      loDate = (loDate).strftime("%Y-%m-%d").to_s

      #VE version
      atVersion = ""
      if ejson["VEVersion"]
        atVersion = "v." + ejson["VEVersion"] + " "
      end
      atVersion = atVersion + "(http://github.com/ging/vish_editor)"


      #Building LOM XML

      myxml.general do
        
        if !loId.nil?
          myxml.identifier do
            if loIdIsURI
              myxml.catalog("URI")
            else
              myxml.catalog("URN")
            end
            myxml.entry(loId)
          end
        end

        myxml.title do
          if ejson["title"]
            myxml.string(ejson["title"], loLanOpts)
          else
            myxml.string("Untitled", :language=> metadataLanguage)
          end
        end

        if loLanguage
          myxml.language(loLanguage)
        end
        
        myxml.description do
          if ejson["description"]
            myxml.string(ejson["description"], loLanOpts)
          elsif ejson["title"]
            myxml.string(ejson["title"] + ". A Virtual Excursion provided by " + Vish::Application.config.full_domain + ".", :language=> metadataLanguage)
          else
            myxml.string("Virtual Excursion provided by " + Vish::Application.config.full_domain + ".", :language=> metadataLanguage)
          end
        end
        if ejson["tags"] && ejson["tags"].kind_of?(Array)
          ejson["tags"].each do |tag|
            myxml.keyword do
              myxml.string(tag.to_s, loLanOpts)
            end
          end
        end
        #Add subjects as additional keywords
        if ejson["subject"]
          if ejson["subject"].kind_of?(Array)
            ejson["subject"].each do |subject|
              myxml.keyword do
                myxml.string(subject, loLanOpts)
              end 
            end
          elsif ejson["subject"].kind_of?(String)
            myxml.keyword do
                myxml.string(ejson["subject"], loLanOpts)
            end
          end
        end

        myxml.structure do
          myxml.source("LOMv1.0")
          myxml.value("hierarchical")
        end
        myxml.aggregationLevel do
          myxml.source("LOMv1.0")
          myxml.value("2")
        end
      end

      myxml.lifeCycle do
        myxml.version do
          myxml.string("v"+loDate.gsub("-","."), :language=>metadataLanguage)
        end
        myxml.status do
          myxml.source("LOMv1.0")
          if ejson["vishMetadata"] and ejson["vishMetadata"]["draft"]==="true"
            myxml.value("draft")
          else
            myxml.value("final")
          end
        end

        if !authorName.nil?
          myxml.contribute do
            myxml.role do
              myxml.source("LOMv1.0")
              myxml.value("author")
            end
            authorEntity = Lom.generateVCard(authorName)
            myxml.entity(authorEntity)
            
            myxml.date do
              myxml.dateTime(loDate)
              unless _LOMschema == "ODS"
                myxml.description do
                  myxml.string("This date represents the date the author finished the indicated version of the Learning Object.", :language=> metadataLanguage)
                end
              end
            end
          end
        end
        myxml.contribute do
          myxml.role do
            myxml.source("LOMv1.0")
            myxml.value("technical implementer")
          end
          authoringToolName = "Authoring Tool ViSH Editor " + atVersion
          authoringToolEntity = Lom.generateVCard(authoringToolName)
          myxml.entity(authoringToolEntity)
        end
      end

      myxml.metaMetadata do
        unless excursionInstance.nil?
          myxml.identifier do
            myxml.catalog("URI")
            myxml.entry(Rails.application.routes.url_helpers.excursion_url(:id => excursionInstance.id) + "/metadata.xml")
          end
        end
        unless authorName.nil?
          myxml.contribute do
            myxml.role do
              myxml.source("LOMv1.0")
              myxml.value("creator")
            end
            myxml.entity(Lom.generateVCard(authorName))
            myxml.date do
              myxml.dateTime(loDate)
              unless _LOMschema == "ODS"
                myxml.description do
                  myxml.string("This date represents the date the author finished authoring the metadata of the indicated version of the Learning Object.", :language=> metadataLanguage)
                end
              end
            end

          end
        end
        myxml.metadataSchema("LOMv1.0")
        myxml.language(metadataLanguage)
      end

      myxml.technical do
        myxml.format("text/html")
        if !loLocation.nil?
          myxml.location(loLocation)
        end
        myxml.requirement do
          myxml.orComposite do
            myxml.type do
              myxml.source("LOMv1.0")
              myxml.value("browser")
            end
            myxml.name do
              myxml.source("LOMv1.0")
              myxml.value("any")
            end
          end
        end
        myxml.installationRemarks do
          myxml.string("Unzip the zip file and launch excursion.html in your browser.", :language=> metadataLanguage)
        end
        myxml.otherPlatformRequirements do
          otherPlatformRequirements = "HTML5-compliant web browser"
          if ejson["VEVersion"]
            otherPlatformRequirements += " and ViSH Viewer " + atVersion
          end
          otherPlatformRequirements += "."
          myxml.string(otherPlatformRequirements, :language=> metadataLanguage)
        end
      end

      myxml.educational do
        myxml.interactivityType do
          myxml.source("LOMv1.0")
          myxml.value("mixed")
        end

        if !Lom.getLearningResourceType("lecture", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("lecture")
          end
        end
        if !Lom.getLearningResourceType("presentation", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("presentation")
          end
        end
        if !Lom.getLearningResourceType("slide", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("slide")
          end
        end
        presentationElements = VishEditorUtils.getElementTypes(ejson) rescue []
        if presentationElements.include?("text") and !Lom.getLearningResourceType("narrative text", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("narrative text")
          end
        end
        if presentationElements.include?("quiz") and !Lom.getLearningResourceType("questionnaire", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("questionnaire")
          end
        end
        myxml.interactivityLevel do
          myxml.source("LOMv1.0")
          myxml.value("very high")
        end
        myxml.intendedEndUserRole do
          myxml.source("LOMv1.0")
          myxml.value("learner")
        end
        _LOMcontext = Lom.readableContext(ejson["context"], _LOMschema)
        if _LOMcontext
          myxml.context do
            myxml.source("LOMv1.0")
            myxml.value(_LOMcontext)
          end
        end
        if ejson["age_range"]
          myxml.typicalAgeRange do
            myxml.string(ejson["age_range"], :language=> metadataLanguage)
          end
        end
        if ejson["difficulty"]
          myxml.difficulty do
            myxml.source("LOMv1.0")
            myxml.value(ejson["difficulty"])
          end
        end
        if ejson["TLT"]
          myxml.typicalLearningTime do
            myxml.duration(ejson["TLT"])
          end
        end
        if ejson["educational_objectives"]
          myxml.description do
            myxml.string(ejson["educational_objectives"], loLanOpts)
          end
        end
        if loLanguage
          myxml.language(loLanguage)                 
        end
      end

      myxml.rights do
        loLicense = nil
        unless ejson["license"].nil? or ejson["license"]["key"].blank?
          licenseInstance = License.find_by_key(ejson["license"]["key"])
          unless licenseInstance.nil?
            loLicense = "License: '" + licenseInstance.name(metadataLanguage) + "'."
          end
        end
        myxml.cost do
          myxml.source("LOMv1.0")
          myxml.value("no")
        end
        unless loLicense.blank?
          myxml.copyrightAndOtherRestrictions do
            myxml.source("LOMv1.0")
            myxml.value("yes")
          end
        end
        myxml.description do
          if loLicense.blank?
            myxml.string("For additional information or questions regarding copyright, distribution and reproduction, visit " + Vish::Application.config.full_domain + "/terms_of_use .", :language=> metadataLanguage)
          else
            myxml.string(loLicense, :language=> metadataLanguage)
          end
        end
      end

      #Annotations (include comments if any).
      unless excursionInstance.nil?
        comments = excursionInstance.post_activity.comments
        unless comments.blank?
          comments.map{|commentActivity| commentActivity.activity_objects.first}.reject{|c| c.nil? or c.description.blank?}.first(30).each do |comment|
            myxml.annotation do
              unless comment.author.nil? or comment.author.name.blank?
                myxml.entity(Lom.generateVCard(comment.author.name))
              end
              unless comment.created_at.nil?
                myxml.date do
                  myxml.dateTime(comment.created_at.strftime("%Y-%m-%d").to_s)
                end
              end
              myxml.description do
                myxml.string(comment.description)
              end
            end
          end
        end
      end

      #Classification (include categories of the ViSH catalogue if any)
      if VishConfig.getAvailableServices.include?("Catalogue")
        if ejson["tags"] && ejson["tags"].kind_of?(Array)
          categoryKeywords = Vish::Application.config.catalogue["category_keywords"]
          catalogueKeywords = categoryKeywords.select{|k,v| v.is_a? Array and (v & ejson["tags"]).length > 1}.map{|k,v| k}
          if catalogueKeywords.length > 0
            myxml.classification do
              myxml.purpose do
                myxml.source("LOMv1.0")
                myxml.value("discipline")
              end
              catalogueKeywords.each do |catalogueCategory|
                myxml.taxonPath do
                  myxml.source do
                    myxml.string("ViSH", :language => metadataLanguage)
                  end
                  myxml.taxon do
                    tagRecord = ActsAsTaggableOn::Tag.find_by_name(catalogueCategory)
                    unless tagRecord.nil?
                      myxml.id(tagRecord.id.to_s)
                    end
                    myxml.entry do
                      myxml.string(catalogueCategory, :language => metadataLanguage)
                    end
                  end
                end
              end
              catalogueKeywords.each do |catalogueCategory|
                myxml.keyword do
                  myxml.string(catalogueCategory, :language => metadataLanguage)
                end
              end
            end
          end
          
        end
      end
      
    end

    myxml
  end


  ####################
  ## IMS QTI 2.1 Management (Handled by the IMSQTI module imsqti.rb)
  ####################

  def self.createQTI(folderPath,fileName,qjson)
    require 'imsqti'
    IMSQTI.createQTI(folderPath,fileName,qjson)
  end


  ####################
  ## Moodle Quiz XML Management (Handled by the MOODLEXML module moodlexml.rb)
  ####################

  def  self.createMoodleQUIZXML(folderPath,fileName,qjson)
    require 'moodlexml'
    MOODLEQUIZXML.createMoodleQUIZXML(folderPath,fileName,qjson)
  end


  ####################
  ## Excursion to PDF Management
  ####################

  def to_pdf
    if self.pdf_needs_generate and !Vish::Application.config.APP_CONFIG["selenium"].nil?
      
      remote = (!Vish::Application.config.APP_CONFIG["selenium"]["remote"].blank? and !Vish::Application.config.APP_CONFIG["selenium"]["remoteFolder"].blank?)
      
      vishPdfFolder = "#{Rails.root}/public/pdf/excursions/#{self.id}"
      Dir.mkdir(vishPdfFolder) unless File.exists?(vishPdfFolder) #Create folder if not exists

      if remote
        pdfFolder = Vish::Application.config.APP_CONFIG["selenium"]["remoteFolder"] + "/#{self.id}"
        Dir.mkdir(pdfFolder) unless File.exists?(pdfFolder)
      else
        pdfFolder = vishPdfFolder
      end

      #Selenium save the screenshots in the pdfFolder
      thumbnails = generate_thumbnails(remote,pdfFolder)

      unless thumbnails.nil? or thumbnails.length < 1
        
        ##Generate PDF using RMagick
        # require 'RMagick'
        # pdf = File.open(pdfFolder+"/#{self.id}.pdf", 'w')
        # images = []
        # thumbnails.each do |thumbnail|
        #   images.push(pdfFolder + "/#{thumbnail}")
        # end
        # pdf_image_list = ::Magick::ImageList.new
        # pdf_image_list.read(*images)
        # pdf_image_list.write(pdfFolder + "/#{self.id}.pdf")
        # pdf.close

        ##Generate PDF using ImageMagick
        #Imagemagick command example: convert 785_1.png  785_1_1.png 785_1_2.png 785_1_3.png 984c.pdf
        pdf_file_name = "#{self.id}.pdf"
        image_list = thumbnails.join(" ")
        
        if remote
          system "cd #{pdfFolder}; convert #{image_list} #{pdf_file_name}"
          #Copy file from SeleniumServer to ViSH Server
          system "cp #{pdfFolder}/#{pdf_file_name} #{vishPdfFolder}/#{pdf_file_name}"
        else
          system "cd #{pdfFolder}; convert #{image_list} #{pdf_file_name}"
        end

        self.update_column(:pdf_timestamp, Time.now)
      end
    end
  end

  def generate_thumbnails(remote,pdfFolder)
    thumbnails = []

    return thumbnails if Vish::Application.config.APP_CONFIG["selenium"].nil? or Vish::Application.config.APP_CONFIG["selenium"]["browser"].blank?

    begin
      require 'selenium-webdriver'

      #Set selenium browser and driver
      seleniumBrowser = Vish::Application.config.APP_CONFIG["selenium"]["browser"].downcase.to_sym
      profile = nil
      
      unless Vish::Application.config.APP_CONFIG["selenium"]["profile"].blank?
        #Load a specific profile (https://code.google.com/p/selenium/wiki/RubyBindings#Tweaking_profile_preferences)
        profile = Vish::Application.config.APP_CONFIG["selenium"]["profile"]
      end

      unless remote
        #Local
        unless Vish::Application.config.APP_CONFIG["selenium"]["driver_path"].blank?
          if seleniumBrowser == :chrome
            Selenium::WebDriver::Chrome.path = Vish::Application.config.APP_CONFIG["selenium"]["driver_path"]
          elsif seleniumBrowser == :firefox
            Selenium::WebDriver::Firefox.path = Vish::Application.config.APP_CONFIG["selenium"]["driver_path"]
            profile = Selenium::WebDriver::Firefox::Profile.from_name "default"
          end
        end
        unless profile.nil?
          driver = Selenium::WebDriver.for seleniumBrowser, :profile => profile
        else
          driver = Selenium::WebDriver.for seleniumBrowser
        end
      else
        #Remote
        if seleniumBrowser == :chrome
          capabilities = Selenium::WebDriver::Remote::Capabilities.chrome()
          #Possible capabilities: https://sites.google.com/a/chromium.org/chromedriver/capabilities
          unless Vish::Application.config.APP_CONFIG["selenium"]["driver_path"].blank?
            capabilities[:binary] = Vish::Application.config.APP_CONFIG["selenium"]["driver_path"]
          end
        elsif seleniumBrowser == :firefox
          capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(:firefox_profile => profile)
          unless Vish::Application.config.APP_CONFIG["selenium"]["driver_path"].blank?
            capabilities[:binary] = Vish::Application.config.APP_CONFIG["selenium"]["driver_path"]
          end
        end

        driver = Selenium::WebDriver.for(:remote, :url => Vish::Application.config.APP_CONFIG["selenium"]["remote"], :desired_capabilities => capabilities)
      end


      #Interact with the driver

      excursion_url = self.getUrl + ".full"

      # driver.navigate.to excursion_url
      driver.get excursion_url

      #Specify screenshots dimensions
      width = 775
      height = 1042
      driver.execute_script %Q{ window.resizeTo(#{width}, #{height}); }

      #Hide fullscreen button
      driver.execute_script %Q{ $("#page-fullscreen").hide(); }
      #Hide other elements, not useful or annoying in printed versions
      driver.execute_script %Q{ $("#page-switcher-start, #page-switcher-end").hide(); }
      driver.execute_script %Q{ $(".buttonQuiz").hide(); }
      
      #Disable non-iframe alerts
      driver.execute_script %Q{ window.alert = function(){}; }

      #Get slidesQuantity
      slidesQuantity = driver.execute_script %Q{ 
        return VISH.Slides.getSlidesQuantity();
      }

      #Take a screenshot of each slide
      slidesQuantity.times do |num|
        driver.execute_script %Q{
          VISH.Slides.goToSlide(#{num+1});
        }
        driver.execute_script %Q{ 
          $("article.current").css("display","block");
          $("article").not(".current").css("display","none");
        }

        Selenium::WebDriver::Wait.new(:timeout => 120).until {
          # TODO:// VISH.SlideManager.isSlideLoaded()
          driver.execute_script("return true")
        }
        #Wait a constant period
        sleep 2.5

        #Remove alerts (if present)
        driver.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError

        driver.save_screenshot(pdfFolder + "/#{self.id}_#{num+1}.png")

        thumbnails.push("#{self.id}_#{num+1}.png");

        isSlideset = driver.execute_script %Q{ 
          return VISH.Slideset.isSlideset(VISH.Slides.getCurrentSlide())
        }

        if isSlideset 
          #Look for subslides
          subslidesIds = (driver.execute_script %Q{ 
            array = []; 
            $(VISH.Slides.getCurrentSlide()).children("article").each(function(index,value){ array.push($(value).attr("id")) }); 
            return array.join(",");
          }).split(",")

          subslidesIds.each_with_index do|sid,index|

            driver.execute_script %Q{ 
              $("#"+"#{sid}").css("display","block");
              VISH.Slides.openSubslide("#{sid}");
            }
            sleep 3.0
            driver.save_screenshot(pdfFolder + "/#{self.id}_#{num+1}_#{index+1}.png")
            thumbnails.push("#{self.id}_#{num+1}_#{index+1}.png");
            driver.execute_script %Q{ 
              VISH.Slides.closeSubslide("#{sid}");
            }
            sleep 0.5
          end
        end

      end

      driver.quit
      return thumbnails

    rescue Exception => e
      begin
        driver.quit
      rescue
      end
      #puts e.message
      return nil
    end
  end

  def pdf_needs_generate
    if self.pdf_timestamp.nil? or self.updated_at > self.pdf_timestamp or !File.exist?("#{Rails.root}/public/pdf/excursions/#{self.id}/#{self.id}.pdf")
      return true
    else
      return false
    end
  end

  def remove_pdf
    if File.exist?("#{Rails.root}/public/pdf/excursions/#{self.id}")
      FileUtils.rm_rf("#{Rails.root}/public/pdf/excursions/#{self.id}") 
    end
  end


  ####################
  ## Other Methods
  #################### 

  def afterPublish
    #Check if post_activity is public. If not, make it public and update the created_at param.
    post_activity = self.post_activity
    unless post_activity.nil? or post_activity.public?
      #Update the created_at param.
      post_activity.created_at = Time.now
      #Make it public
      post_activity.relation_ids = [Relation::Public.instance.id]
      post_activity.save!
    end

    #Try to infer the language of the excursion if it is not spcifiyed
    if (self.language.nil? or !self.language.is_a? String or self.language=="independent")
      self.inferLanguage
    end

    if self.notified_teacher == true
      self.notified_teacher = false
      self.save
    end

    #If LOEP is enabled and Excursion is evaluable, register the excursion in LOEP
    if VishConfig.getAvailableEvaluableModels.include?("Excursion")
      VishLoep.sendActivityObject(self.activity_object) rescue nil
    end
  end

  def inferLanguage
    unless Vish::Application.config.APP_CONFIG["languageDetectionAPIKEY"].nil?
      stringToTestLanguage = ""
      if self.title.is_a? String and !self.title.blank?
        stringToTestLanguage = stringToTestLanguage + self.title + " "
      end
      if self.description.is_a? String and !self.description.blank?
        stringToTestLanguage = stringToTestLanguage + self.description + " "
      end

      if stringToTestLanguage.is_a? String and !stringToTestLanguage.blank?
        
        begin
          detectionResult = DetectLanguage.detect(stringToTestLanguage)
        rescue Exception => e
          detectionResult = []
        end
        
        validLanguageCodes = ["de","en","es","fr","it","pt","ru"]

        detectionResult.each do |result|
          if result["isReliable"] == true
            detectedLanguageCode = result["language"]
            if validLanguageCodes.include? detectedLanguageCode
              lan = detectedLanguageCode
            else
              lan = "ot"
            end

            #Update language
            self.activity_object.update_column :language, lan
            eJson = JSON(self.json)
            eJson["language"] = lan
            self.update_column :json, eJson.to_json
            break
          end
        end
      end
    end
  end

  def clone_for sbj
    return nil if sbj.blank?
    unless self.clonable? or sbj.admin? or (sbj===self.owner)
      return nil
    end

    contributors = self.contributors || []
    contributors.push(self.author)
    contributors.uniq!
    contributors.delete(sbj)

    e=Excursion.new
    e.author=sbj
    e.owner=sbj
    e.user_author=sbj.user.actor

    eJson = JSON(self.json)
    eJson["author"] = {name: sbj.name, vishMetadata:{ id: sbj.id }}
    unless contributors.blank?
      eJson["contributors"] = contributors.map{|c| {name: c.name, vishMetadata:{ id: c.id}}}
    end
    eJson.delete("license")
    eJson["vishMetadata"] = {draft: "true"}
    e.json = eJson.to_json

    e.contributors=contributors
    e.draft=true
    e.save!
    e
  end

  #method used to return json objects to the recommendation in the last slide
  def reduced_json(controller)
      rjson = {
        :id => id,
        :url => controller.excursion_url(:id => self.id),
        :title => title,
        :author => author.name,
        :description => description,
        :image => thumbnail_url ? thumbnail_url : Vish::Application.config.full_domain + "/assets/logos/original/excursion-00.png",
        :views => visit_count,
        :favourites => like_count,
        :number_of_slides => slide_count
      }
      
      unless self.score_tracking.nil?
        rjson[:recommender_data] = self.score_tracking
        rsEngineCode = TrackingSystemEntry.getRSCode(JSON(rjson[:recommender_data])["rec"])
        rjson[:url] = controller.excursion_url(:id => self.id, :rec => rsEngineCode) unless rsEngineCode.nil?
      end

      rjson
  end

  def increment_download_count
    self.activity_object.increment_download_count
  end

  def get_attachment_name
    name = "excursion_" + self.id.to_s + "_attachment" + File.extname(self.attachment_file_name)
    name
  end

  ####################
  ## Quality Metrics
  ####################

  #See app/decorators/social_stream/base/activity_object_decorator.rb
  #Method calculate_qscore



  private

  def fill_license
    #Set public license when publishing a excursion
    if ((self.scope_was!=0 or self.new_record?) and (self.scope==0))
      if self.license.nil? or self.license.private?
        license_metadata = JSON(self.json)["license"] rescue nil
        if license_metadata.is_a? Hash and license_metadata["key"].is_a? String
          license = License.find_by_key(license_metadata["key"])
          unless license.nil?
            self.license_id = license.id
          end
        end
        if self.license.nil? or self.license.private?
          self.license_id = License.default.id
        end
      end
    end
  end

  def parse_for_meta
    parsed_json = JSON(json)

    activity_object.title = parsed_json["title"] ? parsed_json["title"] : "Untitled"
    activity_object.description = parsed_json["description"]
    activity_object.tag_list = parsed_json["tags"]
    activity_object.language = parsed_json["language"]

    unless parsed_json["age_range"].blank?
      begin
        ageRange = parsed_json["age_range"]
        activity_object.age_min = ageRange.split("-")[0].delete(' ')
        activity_object.age_max = ageRange.split("-")[1].delete(' ')
      rescue
      end
    end

    if self.draft
      activity_object.scope = 1 #private
    else
      activity_object.scope = 0 #public
    end
    
    #Permissions
    activity_object.allow_download = !(parsed_json["allow_download"] == "false")
    activity_object.allow_comment = !(parsed_json["allow_comment"] == "false")
    activity_object.allow_clone = !(parsed_json["allow_clone"] == "false")

    original_updated_at = self.updated_at
    activity_object.save!

    #Ensure that the updated_at value of the AO is consistent with the object
    #Prevent admin to modify updated_at values as well.
    self.update_column :updated_at, original_updated_at
    activity_object.update_column :updated_at, original_updated_at

    unless parsed_json["vishMetadata"]
      parsed_json["vishMetadata"] = {}
    end
    parsed_json["vishMetadata"]["id"] = self.id.to_s
    parsed_json["vishMetadata"]["draft"] = self.draft.to_s
    unless self.draft
      parsed_json["vishMetadata"]["released"] = "true"
    end
    
    parsed_json["author"] = {name: author.name, vishMetadata:{ id: author.id }}

    self.update_column :json, parsed_json.to_json
    self.update_column :slide_count, parsed_json["slides"].size
    self.update_column :thumbnail_url, parsed_json["avatar"] ? parsed_json["avatar"] : Vish::Application.config.full_domain + "/assets/logos/original/excursion-00.png"
  end

  # Ensure that activity inside the activity_object is not nil. Social Stream does not guarantee this 100%.
  def fix_post_activity_nil
    if self.post_activity == nil
      a = Activity.new :verb         => "post",
                       :author_id    => self.activity_object.author_id,
                       :user_author  => self.activity_object.user_author,
                       :owner        => self.activity_object.owner,
                       :relation_ids => self.activity_object.relation_ids,
                       :parent_id    => self.activity_object._activity_parent_id

      a.activity_objects << self.activity_object

      a.save!
    end
  end

  def send_to_loep
    #If LOEP is enabled, send the excursion to LOEP.
    #It will be created or updated
    if self.public_scope? and !Vish::Application.config.APP_CONFIG['loep'].nil?
      VishLoep.sendActivityObject(self.activity_object) rescue nil
    end
  end
  
end