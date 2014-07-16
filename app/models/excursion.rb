# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.
require 'builder'

class Excursion < ActiveRecord::Base
  include SocialStream::Models::Object
  has_many :excursion_contributors, :dependent => :destroy
  has_many :contributors, :class_name => "Actor", :through => :excursion_contributors

  validates_presence_of :json
  before_save :fix_relation_ids_drafts
  after_save :parse_for_meta
  after_save :fix_post_activity_nil
  after_destroy :remove_scorm
  after_destroy :remove_pdf
  
  define_index do
    activity_object_index
    
    has id
    has slide_count
    has draft
  end

  attr_accessor :score
  attr_accessor :score_tracking


  ####################
  ## Model methods
  ####################

  def to_json(options=nil)
    json
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

  def to_scorm(controller)
    if self.scorm_needs_generate
      filePath = "#{Rails.root}/public/scorm/excursions/"
      fileName = self.id
      json = JSON(self.json)
      Excursion.createSCORM(filePath,fileName,json,self,controller)
      self.update_column(:scorm_timestamp, Time.now)
    end
  end

  def scorm_needs_generate
    if self.scorm_timestamp.nil? or self.updated_at > self.scorm_timestamp or !File.exist?("#{Rails.root}/public/scorm/excursions/#{self.id}.zip")
      return true
    else
      return false
    end
  end

  def remove_scorm
    if File.exist?("#{Rails.root}/public/scorm/excursions/#{self.id}.zip")
      File.delete("#{Rails.root}/public/scorm/excursions/#{self.id}.zip") 
    end
  end

  def self.createSCORM(filePath,fileName,json,excursion,controller)
    require 'zip/zip'
    require 'zip/zipfilesystem'

    # filePath = "#{Rails.root}/public/scorm/excursions/"
    # fileName = self.id
    # json = JSON(self.json)
    t = File.open("#{filePath}#{fileName}.zip", 'w')

    #Add manifest, main HTML file and additional files
    Zip::ZipOutputStream.open(t.path) do |zos|
      xml_manifest = Excursion.generate_scorm_manifest(json,excursion)
      zos.put_next_entry("imsmanifest.xml")
      zos.print xml_manifest.target!()

      zos.put_next_entry("excursion.html")
      zos.print controller.render_to_string "show.scorm.erb", :locals => {:excursion=>excursion, :json => json}, :layout => false  
    end

    #Add required XSD files and folders
    xsdFileDir = "#{Rails.root}/public/xsd"
    xsdFiles = ["adlcp_v1p3.xsd","adlnav_v1p3.xsd","adlseq_v1p3.xsd","imscp_v1p1.xsd","imsss_v1p0.xsd","lom.xsd"]
    xsdFolders = ["common","extend","unique","vocab"]

    #Add required xsd files
    Zip::ZipFile.open(t.path, Zip::ZipFile::CREATE) { |zipfile|
      xsdFiles.each do |xsdFileName|
        zipfile.add(xsdFileName,xsdFileDir+"/"+xsdFileName)
      end
    }

    #Add required XSD folders
    xsdFolders.each do |xsdFolderName|
      zip_folder(t.path,xsdFileDir,xsdFileDir+"/"+xsdFolderName)
    end

    #Copy SCORM assets (image, javascript and css files)
    dir = "#{Rails.root}/vendor/plugins/vish_editor/app/scorm"
    zip_folder(t.path,dir)

    #Add theme
    themesPath = "#{Rails.root}/vendor/plugins/vish_editor/app/assets/images/themes/"
    theme = "theme1" #Default theme
    if json["theme"] and File.exists?(themesPath + json["theme"])
      theme = json["theme"]
    end
    #Copy excursion theme
    zip_folder(t.path,"#{Rails.root}/vendor/plugins/vish_editor/app/assets",themesPath + theme)

    t.close
  end

  def self.zip_folder(zipFilePath,root,dir=nil)
    unless dir 
      dir = root
    end

    #Get subdirectories
    Dir.chdir(dir)
    subdir_list=Dir["*"].reject{|o| not File.directory?(o)}
    subdir_list.each do |subdirectory|
      subdirectory_path = "#{dir}/#{subdirectory}"
      zip_folder(zipFilePath,root,subdirectory_path)
    end

    #Look for files
    Zip::ZipFile.open(zipFilePath, Zip::ZipFile::CREATE) { |zipfile|
      Dir.foreach(dir) do |item|
        item_path = "#{dir}/#{item}"
        if File.file?item_path
          rpath = String.new(item_path)
          rpath.slice! root + "/"
          zipfile.add(rpath,item_path)
        end
      end
    }
  end

  # Metadata based on LOM (Learning Object Metadata) standard
  # LOM final draft: http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf
  def self.generate_scorm_manifest(ejson,excursion,options=nil)
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
    myxml.manifest("identifier"=>"VISH_VIRTUAL_EXCURSION_" + identifier,
      "version"=>"1.3",
      "xmlns"=>"http://www.imsglobal.org/xsd/imscp_v1p1",
      "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_v1p3",
      "xmlns:adlseq"=>"http://www.adlnet.org/xsd/adlseq_v1p3",
      "xmlns:adlnav"=>"http://www.adlnet.org/xsd/adlnav_v1p3",
      "xmlns:imsss"=>"http://www.imsglobal.org/xsd/imsss",
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd",
    ) do

      myxml.metadata() do
        myxml.schema("ADL SCORM")
        myxml.schemaversion("2004 4th Edition")
        #Add LOM metadata
        Excursion.generate_LOM_metadata(ejson,excursion,{:target => myxml, :id => lomIdentifier, :LOMschema => (options and options[:LOMschema]) ? options[:LOMschema] : "custom"})
      end

      myxml.organizations('default'=>"defaultOrganization") do
        myxml.organization('identifier'=>"defaultOrganization", 'structure'=>"hierarchical") do
          if ejson["title"]
            myxml.title(ejson["title"])
          else
            myxml.title("Untitled")
          end
          myxml.item('identifier'=>"VIRTUAL_EXCURSION_" + identifier,'identifierref'=>"VIRTUAL_EXCURSION_" + identifier + "_RESOURCE") do
            if ejson["title"]
              myxml.title(ejson["title"])
            else
              myxml.title("Untitled")
            end
          end
        end
      end

      myxml.resources do         
        myxml.resource('identifier'=>"VIRTUAL_EXCURSION_" + identifier + "_RESOURCE", 'type'=>"webcontent", 'href'=>"excursion.html", 'adlcp:scormType'=>"sco") do
          myxml.file('href'=> "excursion.html")
        end
      end

    end    

    return myxml
  end



  ####################
  ## LOM Metadata
  ####################

  def self.generate_LOM_metadata(ejson, excursion, options=nil)
    _LOMschema = "custom"

    supportedLOMSchemas = ["custom","loose","ODS","ViSH"]
    if options and options[:LOMschema] and supportedLOMSchemas.include? options[:LOMschema]
      _LOMschema = options[:LOMschema]
    end

    if options and options[:target]
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

      if options and options[:id]
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

      #Location
      loLocation = nil
      if excursion
        if excursion.draft == false
          loLocation = Rails.application.routes.url_helpers.excursion_url(:id => excursion.id)
        end
      elsif ejson["vishMetadata"] and ejson["vishMetadata"]["id"] and (ejson["vishMetadata"]["draft"] == false or ejson["vishMetadata"]["draft"] == "false")
        begin
          excursionInstance = Excursion.find(ejson["vishMetadata"]["id"])
          loLocation = Rails.application.routes.url_helpers.excursion_url(:id => excursionInstance.id)
        rescue
        end
      end

      #Language (LO language and metadata language)
      loLanguage = getLOMLoLanguage(ejson["language"], _LOMschema)
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
            authorEntity = generateVCard(authorName)
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
          authoringToolEntity = generateVCard(authoringToolName)
          myxml.entity(authoringToolEntity)
        end
      end

      myxml.metaMetadata do
        if !loId.nil? and loIdIsURI and excursion
          myxml.identifier do
            myxml.catalog("URI")
            myxml.entry(Rails.application.routes.url_helpers.excursion_url(:id => excursion.id) + "/metadata.xml")
          end

          if !authorName.nil?
            myxml.contribute do
              myxml.role do
                myxml.source("LOMv1.0")
                myxml.value("creator")
              end

              creatorEntity = generateVCard(authorName)
              myxml.entity(creatorEntity)
              
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
        myxml.otherPlatformRequirements do
          myxml.string("HTML5-compliant web browser", :language=> metadataLanguage)
          if ejson["VEVersion"]
            myxml.string("ViSH Viewer " + atVersion, :language=> metadataLanguage)
          end
        end
      end

      myxml.educational do
        myxml.interactivityType do
          myxml.source("LOMv1.0")
          myxml.value("mixed")
        end

        if !getLearningResourceType("lecture", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("lecture")
          end
        end
        if !getLearningResourceType("presentation", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("presentation")
          end
        end
        if !getLearningResourceType("slide", _LOMschema).nil?
          myxml.learningResourceType do
            myxml.source("LOMv1.0")
            myxml.value("slide")
          end
        end
        #TODO: Explore JSON and include more elements.

        myxml.interactivityLevel do
          myxml.source("LOMv1.0")
          myxml.value("very high")
        end
        myxml.intendedEndUserRole do
          myxml.source("LOMv1.0")
          myxml.value("learner")
        end
        _LOMcontext = readableContext(ejson["context"], _LOMschema)
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
        if ejson["TLT"] or ejson["slides"]
          myxml.typicalLearningTime do
            if ejson["TLT"]
              myxml.duration(ejson["TLT"])
            else
              #Inferred
              # 1 min per slide
              # inferredTPL = (excursion.slide_count * 1).to_s
              inferredTPL = (ejson["slides"].length * 1).to_s
              myxml.duration("PT"+inferredTPL+"M0S")
            end
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
        myxml.cost do
          myxml.source("LOMv1.0")
          myxml.value("no")
        end

        myxml.copyrightAndOtherRestrictions do
          myxml.source("LOMv1.0")
          myxml.value("yes")
        end

        myxml.description do
          myxml.string("For additional information or questions regarding copyright, distribution and reproduction, visit " + Vish::Application.config.full_domain + "/legal_notice", :language=> metadataLanguage)
        end

      end
      
    end

    myxml
  end

  def self.getLOMLoLanguage(language, _LOMschema)
    #List of language codes according to ISO-639:1988
    # lanCodes = ["aa","ab","af","am","ar","as","ay","az","ba","be","bg","bh","bi","bn","bo","br","ca","co","cs","cy","da","de","dz","el","en","eo","es","et","eu","fa","fi","fj","fo","fr","fy","ga","gd","gl","gn","gu","gv","ha","he","hi","hr","hu","hy","ia","id","ie","ik","is","it","iu","ja","jw","ka","kk","kl","km","kn","ko","ks","ku","kw","ky","la","lb","ln","lo","lt","lv","mg","mi","mk","ml","mn","mo","mr","ms","mt","my","na","ne","nl","no","oc","om","or","pa","pl","ps","pt","qu","rm","rn","ro","ru","rw","sa","sd","se","sg","sh","si","sk","sl","sm","sn","so","sq","sr","ss","st","su","sv","sw","ta","te","tg","th","ti","tk","tl","tn","to","tr","ts","tt","tw","ug","uk","ur","uz","vi","vo","wo","xh","yi","yo","za","zh","zu"]
    lanCodesMin = ["de","en","es","fr","it","pt","hu"]

    case _LOMschema
    when "ODS"
      #ODS requires language, and admits blank language.
      if language.nil? or language == "independent" or !lanCodesMin.include?(language)
        return "none"
      end
    else
      #When language=nil, no language attribute is provided
      if language.nil? or language == "independent" or !lanCodesMin.include?(language)
        return nil
      end
    end

    #It is included in the lanCodes array
    return language
  end

  def self.readableContext(context, _LOMschema)
    case _LOMschema
    when "ODS" 
      #ODS LOM Extension
      #According to ODS, context has to be one of ["primary education", "secondary education", "informal context"]
      case context
      when "preschool", "pEducation", "primary education", "school"
        return "primary education"
      when "sEducation", "higher education", "university"
        return "secondary education"
      when "training", "other"
        return "informal context"
      else
        return nil
      end
    when "ViSH"
      #ViSH LOM extension
      case context
      when "unspecified"
        return "Unspecified"
      when "preschool"
        return "Preschool Education"
      when "pEducation"
        return "Primary Education"
      when "sEducation"
        return "Secondary Education"
      when "higher education"
        return "Higher Education"
      when "training"
        return "Professional Training"
      when "other"
        return "Other"
      else
        return context
      end
    else
      #Strict LOM mode. Extensions are not allowed
      case context
      when "unspecified"
        return nil
      when "preschool"
      when "pEducation"
      when "sEducation"
        return "school"
      when "higher education"
        return "higher education"
      when "training"
        return "training"
      else
        return "other"
      end
    end
  end

  def self.getLearningResourceType(lreType, _LOMschema)
    case _LOMschema
    when "ODS"
      #ODS LOM Extension
      #According to ODS, the Learning REsources type has to be one of this:
      allowedLREtypes = ["application","assessment","blog","broadcast","case study","courses","demonstration","drill and practice","educational game","educational scenario","learning scenario","pedagogical scenario","enquiry-oriented activity","exercise","experiment","glossaries","guide","learning pathways","lecture","lesson plan","open activity","other","presentation","project","reference","role play","simulation","social media","textbook","tool","website","wiki","audio","data","image","text","video"]
    else
      allowedLREtypes = ["exercise","simulation","questionnaire","diagram","figure","graph","index","slide","table","narrative text","exam","experiment","problem statement","self assessment","lecture"]
    end

    if allowedLREtypes.include? lreType
      return lreType
    else
      return nil
    end
  end

  def self.generateVCard(fullName)
    return "BEGIN:VCARD&#xD;VERSION:3.0&#xD;N:"+fullName+"&#xD;FN:"+fullName+"&#xD;END:VCARD"
  end


  ####################
  ## IMS QTI 2.1 Management (Handled by the IMSQTI module imsqti.rb)
  ####################

  def self.createQTI(filePath,fileName,qjson)
    require 'imsqti'
    IMSQTI.createQTI(filePath,fileName,qjson)
  end


  ####################
  ## Excursion to PDF Management
  ####################

  def to_pdf(controller)
    if self.pdf_needs_generate
      slidesQuantity = generate_thumbnails(controller)
      if slidesQuantity > 0
        pdfFolder = "#{Rails.root}/public/pdf/excursions/#{self.id}"

        #Generate PDF
        pdf = File.open(pdfFolder+"/#{self.id}.pdf", 'w')

        require 'RMagick'
        images = []
        slidesQuantity.times do |num|
          images.push(pdfFolder + "/#{self.id}_#{num+1}.png")
        end
        pdf_image_list = ::Magick::ImageList.new
        pdf_image_list.read(*images)
        pdf_image_list.write(pdfFolder + "/#{self.id}.pdf")
        pdf.close

        self.update_column(:pdf_timestamp, Time.now)
      end
    end
  end

  def generate_thumbnails(controller)
    begin
      #Create folder if not exists
      pdfFolder = "#{Rails.root}/public/pdf/excursions/#{self.id}"
      Dir.mkdir(pdfFolder) unless File.exists?(pdfFolder)

      require 'selenium-webdriver'
      Selenium::WebDriver::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
      driver = Selenium::WebDriver.for :chrome

      # Testing
      # excursion_url = 'http://vishub.org/excursions/55.full'
      
      excursion_url = controller.url_for( :controller => 'excursions', :action => 'show', :format => 'full', :id=>self.id)
      # driver.navigate.to excursion_url
      driver.get excursion_url

      #Specify screenshots dimensions
      width = 775
      height = 1042
      driver.execute_script %Q{ window.resizeTo(#{width}, #{height}); }

      #Hide fullscreen button
      driver.execute_script %Q{ $("#page-fullscreen").hide(); }
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

        Selenium::WebDriver::Wait.new(:timeout => 30).until { 
          # TODO:// VISH.SlideManager.isSlideLoaded()
          driver.execute_script("return true")
        }
        #Wait a constant period
        sleep 1.5

        #Remove alert (if is present)
        driver.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError

        driver.save_screenshot(pdfFolder + "/#{self.id}_#{num+1}.png")
      end

      driver.quit
      return slidesQuantity

    rescue Exception => e
      begin
        driver.quit
      rescue
      end
      puts e.message
      return -1
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
  ## Evaluations
  #################### 

  def evaluations
    ExcursionEvaluation.where(:excursion_id => self.id)
  end

  def averageEvaluation
    evaluations_array = []
    if self.evaluations.length > 0
      6.times do |ind|
        evaluations_array.push(ExcursionEvaluation.average("answer_"+ind.to_s, :conditions=>["excursion_id=?", self.id]).to_f.round(2))
      end
    else
      evaluations_array = [0,0,0,0,0,0]
    end
    evaluations_array
  end

  def numberOfEvaluations
    ExcursionEvaluation.count("answer_1", :conditions=>["excursion_id=?", self.id])
  end

  def learningEvaluations
    ExcursionLearningEvaluation.where(:excursion_id => self.id)
  end

  def averageLearningEvaluation
    evaluations_array = []
    if self.learningEvaluations.length > 0
      6.times do |ind|
        evaluations_array.push(ExcursionLearningEvaluation.average("answer_"+ind.to_s, :conditions=>["excursion_id=?", self.id]).to_f.round(2))
      end
    else
      evaluations_array = [0,0,0,0,0,0]
    end
    evaluations_array
  end

  def numberOfLearningEvaluations
    ExcursionLearningEvaluation.count("answer_1", :conditions=>["excursion_id=?", self.id])
  end



  ####################
  ## Other Methods
  #################### 

  def afterPublish
    #If LOEP is enabled, upload the excursion to LOEP
    if !Vish::Application.config.APP_CONFIG['loep'].nil?
      VishLoep.registerExcursion(self) rescue nil
    end

    #Try to infer the language of the excursion if it is not spcifiyed
    if (self.language.nil? or !self.language.is_a? String or self.language=="independent")
      self.inferLanguage
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
    e=Excursion.new
    e.author=sbj
    e.owner=sbj
    e.user_author=sbj.user.actor

    eJson = JSON(self.json)
    eJson["author"] = {name: sbj.name, vishMetadata:{ id: sbj.id}}
    if eJson["contributors"].nil?
      eJson["contributors"] = []
    end
    eJson["contributors"].push({name: self.author.name, vishMetadata:{ id: self.author.id}})
    e.json = eJson.to_json

    e.contributors=self.contributors.push(self.author)
    e.contributors.uniq!
    e.contributors.delete(sbj)
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
      
      if !self.score_tracking.nil?
        rjson[:recommender_data] = self.score_tracking
      end

      rjson
  end

  #we don't know what happens or how it happens but sometimes in social_stream
  # the activity inside the activity_object is nil, so we fix it here
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

  def increment_download_count
    self.activity_object.increment_download_count
  end

  def is_mostvaluable?
    is_mve
  end

  ####################
  ## Quality Metrics
  ####################

  #See app/decorators/social_stream/base/activity_object_decorator.rb
  #Method calculate_qscore

  #######################
  ## Get Excursion subsets
  ######################

  def self.getPopular(n=20,options={})
    #(options[:page] only works when options[:random]==false)

    random = (options[:random]!=false)

    if random
      nSubset = [80,4*n].max
    else
      nSubset = n
    end

    # Using db queries (old version)
    # Excursion.joins(:activity_object).where("excursions.draft=false and excursions.id not in (?)", ids_to_avoid).order("activity_objects.ranking DESC").limit(nSubset).sample(n)
    
    # Using thinking sphinx
    excursions = RecommenderSystem.search({:n=>nSubset, :order => 'ranking DESC', :models => [Excursion], :users_to_avoid => [options[:user]], :ids_to_avoid => options[:ids_to_avoid], :page => options[:page]})

    if random
      return excursions.first(nSubset).sample(n)
    else
      return excursions
    end
  end

  def self.getIdsToAvoid(preSelection=nil,user=nil)
    ids_to_avoid = []

    if preSelection.is_a? Array
      ids_to_avoid = preSelection.map{|e| e.id}
    end

    if !user.nil?
      ids_to_avoid.concat(Excursion.authored_by(user).map{|e| e.id})
    end

    ids_to_avoid.uniq!

    if !ids_to_avoid.is_a? Array or ids_to_avoid.empty?
      #if ids=[] the queries may returns [], so we fill it with an invalid id (no excursion will ever have id=-1)
      ids_to_avoid = [-1]
    end

    return ids_to_avoid
  end

  private

  def parse_for_meta
    parsed_json = JSON(json)

    activity_object.title = parsed_json["title"] ? parsed_json["title"] : "Title"
    activity_object.description = parsed_json["description"] 
    activity_object.tag_list = parsed_json["tags"]
    activity_object.language = parsed_json["language"]
    begin
      ageRange = parsed_json["age_range"]
      activity_object.age_min = ageRange.split("-")[0].delete(' ')
      activity_object.age_max = ageRange.split("-")[1].delete(' ')
    rescue
    end
    activity_object.save!

    if !parsed_json["vishMetadata"]
      parsed_json["vishMetadata"] = {}
    end
    parsed_json["vishMetadata"]["id"] = self.id.to_s
    parsed_json["vishMetadata"]["draft"] = self.draft.to_s

    parsed_json["author"] = {name: author.name, vishMetadata:{ id: author.id}}

    self.update_column :json, parsed_json.to_json
    self.update_column :slide_count, parsed_json["slides"].size
    self.update_column :thumbnail_url, parsed_json["avatar"] ? parsed_json["avatar"] : Vish::Application.config.full_domain + "/assets/logos/original/excursion-00.png"
  end

  def fix_relation_ids_drafts
    if self.draft
      activity_object.relation_ids=[Relation::Private.instance.id]
    else
      activity_object.relation_ids=[Relation::Public.instance.id]
    end
  end
  
end
