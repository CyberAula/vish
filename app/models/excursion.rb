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
  after_save :parse_for_meta
  before_save :fix_relation_ids_drafts
  after_destroy :remove_scorm
  after_destroy :remove_pdf
  after_save :fix_post_activity_nil

  define_index do
    activity_object_index
    indexes excursion_type
    has slide_count
    has draft
    has activity_object.like_count, :as => :like_count
    has activity_object.visit_count, :as => :visit_count
  end



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
    Excursion.generate_LOM_metadata(JSON(self.json),self,{LOMextension: "ODS", :target => xmlMetadata, :id => identifier})
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

    #Generate Manifest and HTML file
    Zip::ZipOutputStream.open(t.path) do |zos|
      xml_manifest = Excursion.generate_scorm_manifest(json,excursion)
      zos.put_next_entry("imsmanifest.xml")
      zos.print xml_manifest.target!()

      zos.put_next_entry("excursion.html")
      zos.print controller.render_to_string "show.scorm.erb", :locals => {:excursion=>excursion, :json => json}, :layout => false  
    end

    #Copy SCORM assets (image, javascript and css files)
    dir = "#{Rails.root}/vendor/plugins/vish_editor/app/scorm"
    zip_folder(t.path,dir,nil)

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

  def self.zip_folder(zipFilePath,root,dir)
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
  def self.generate_scorm_manifest(ejson,excursion)
    if excursion and !excursion.id.nil?
      identifier = excursion.id.to_s
      lomIdentifier = Rails.application.routes.url_helpers.excursion_url(:id => excursion.id)
    elsif (ejson["vishMetadata"] and ejson["vishMetadata"]["id"])
      identifier = ejson["vishMetadata"]["id"].to_s
      lomIdentifier = "urn:ViSH:" + identifier
    else
      identifier = "TmpSCORM_" + (Site.current.config["tmpJSONcount"].nil? ? "1" : Site.current.config["tmpJSONcount"].to_s)
      lomIdentifier = "urn:ViSH:" + identifier
    end

    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    myxml.manifest("identifier"=>"VISH_VIRTUAL_EXCURSION_" + identifier,
      "version"=>"1.0",
      "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3.xsd http://www.imsglobal.org/xsd/imsss_v1p0.xsd http://ltsc.ieee.org/xsd/LOM/lom.xsd",
      "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_v1p3",
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xmlns"=>"http://www.imsglobal.org/xsd/imscp_v1p1",
      "xmlns:imsss"=>"http://www.imsglobal.org/xsd/imsss",
      "xmlns:lom"=>"http://ltsc.ieee.org/xsd/LOM/lom.xsd" ) do

      myxml.metadata() do
        myxml.schema("ADL SCORM")
        myxml.schemaversion("CAM 1.3")
        #Add LOM metadata
        Excursion.generate_LOM_metadata(ejson,excursion,{:target => myxml, :id => lomIdentifier})
      end

      myxml.organizations('default'=>"defaultOrganization",'structure'=>"hierarchical") do
        myxml.organization('identifier'=>"defaultOrganization") do
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
        myxml.resource('identifier'=>"VIRTUAL_EXCURSION_" + identifier + "_RESOURCE", 'type'=>"webcontent", 'href'=>"excursion.html", 'adlcp:scormtype'=>"sco") do
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
    _LOMmode = "custom"
    _LOMextension = nil

    if options
      if options[:LOMmode]
        _LOMmode = options[:LOMmode]
      end
      if options[:LOMextension]
        _LOMextension = options[:LOMextension]
      end
    end

    if options and options[:target]
      myxml = ::Builder::XmlMarkup.new(:indent => 2, :target => options[:target])
    else
      myxml = ::Builder::XmlMarkup.new(:indent => 2)
      myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    end
   
    #Select LOM Header options
    lomHeaderOptions = {}
    if((_LOMmode != "custom" and _LOMmode != "loose") or (_LOMextension==nil))
      lomHeaderOptions = {}
    else
      #LOMmode allow LOM extensions, and some extension is define
      if _LOMextension == "ODS"
        lomHeaderOptions = { 'xmlns' => "http://ltsc.ieee.org/xsd/LOM",
                             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                             'xsi:schemaLocation' => %{http://ltsc.ieee.org/xsd/LOM lomODS.xsd}
                           }
      else
        #Extension not supported/recognized
        lomHeaderOptions = {}
      end
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
      loLanguage = nil
      if ejson["language"]
        if ejson["language"]!="independent"
          loLanguage = ejson["language"]
        end
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
            myxml.string(ejson["title"], :language=> loLanguage)
          else
            myxml.string("Untitled", :language=> metadataLanguage)
          end
        end

        if loLanguage
          myxml.language(loLanguage)
        end
        
        myxml.description do
          if ejson["description"]
            myxml.string(ejson["description"], :language=> loLanguage)
          elsif ejson["title"]
            myxml.string(ejson["title"] + ". A Virtual Excursion provided by http://vishub.org.", :language=> metadataLanguage)
          else
            myxml.string("Virtual Excursion provided by http://vishub.org.", :language=> metadataLanguage)
          end
        end
        if ejson["tags"] && ejson["tags"].kind_of?(Array)
          ejson["tags"].each do |tag|
            myxml.keyword do
              myxml.string(tag.to_s, :language=> loLanguage)
            end
          end
        end
        #Add subjects as additional keywords
        if ejson["subject"]
          if ejson["subject"].kind_of?(Array)
            ejson["subject"].each do |subject|
              myxml.keyword do
                myxml.string(subject, :language=> loLanguage)
              end 
            end
          elsif ejson["subject"].kind_of?(String)
            myxml.keyword do
                myxml.string(ejson["subject"], :language=> loLanguage)
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

            authorEntity = "BEGIN:VCARD\n\r\n\r VERSION:3.0 \n\r N:"+authorName+"\n\r FN:"+authorName+"\n\r END:VCARD"
            myxml.entity(authorEntity)
            
            myxml.date do
              myxml.dateTime(loDate)
              myxml.description("This date represents the date the author finished the indicated version of the Learning Object.", :language=>metadataLanguage)
            end
          end
        end
        myxml.contribute do
          myxml.role do
            myxml.source("LOMv1.0")
            myxml.value("technical implementer")
          end
          authoringToolName = "Authoring Tool ViSH Editor " + atVersion
          authoringToolEntity = "BEGIN:VCARD\n\r\n\r VERSION:3.0 \n\r N:"+authoringToolName+"\n\r FN:"+authoringToolName+"\n\r END:VCARD"
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

              creatorEntity = "BEGIN:VCARD\n\r\n\r VERSION:3.0 \n\r N:"+authorName+"\n\r FN:"+authorName+"\n\r END:VCARD"
              myxml.entity(creatorEntity)
              
              myxml.date do
                myxml.dateTime(loDate)
                myxml.description("This date represents the date the author finished authoring the metadata of the indicated version of the Learning Object.", :language=>metadataLanguage)
              end
            end
          end

          myxml.metadataSchema("LOMv1.0", :language=>metadataLanguage)
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
        myxml.learningResourceType do
          myxml.source("LOMv1.0")
          myxml.value("lecture")
        end
        myxml.learningResourceType do
          myxml.source("LOMv1.0")
          myxml.value("slide")
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
        _LOMcontext = readableContext(ejson["context"], _LOMmode, _LOMextension)
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
              myxml.string(ejson["educational_objectives"], :language=> loLanguage)
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
          myxml.source("For additional information or questions regarding copyright, distribution and reproduction, visit http://vishub.org/legal_notice", :language=> metadataLanguage)
        end

      end
      
    end

    myxml
  end

  def self.readableContext(context, _LOMmode, _LOMextension)
    if _LOMmode == "custom" or _LOMmode == "loose"
      #Extensions are allowed
      if _LOMextension == "ODS"
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
      else
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



  ####################
  ## IMS QTI 2.1 Management
  ####################

  def self.createQTI(filePath,fileName,qjson)
    require 'zip/zip'
    require 'zip/zipfilesystem'

    t = File.open("#{filePath}#{fileName}.zip", 'w')

    Zip::ZipOutputStream.open(t.path) do |zos|
      case qjson["quiztype"]
      when "truefalse"
        for i in 0..((qjson["choices"].size)-1)
          qti_tf = Excursion.generate_QTITF(qjson,i)
          zos.put_next_entry(fileName +"_" + i.to_s + ".xml")
          zos.print qti_tf.target!()
        end
        main_tf = Excursion.generate_mainQTIMC(qjson,fileName)
        zos.put_next_entry(fileName + ".xml")
        zos.print main_tf

      when "multiplechoice"
        qti_mc = Excursion.generate_QTIMC(qjson)
        zos.put_next_entry(fileName + ".xml")
        zos.print qti_mc.target!()
      else
      end

      xml_truemanifest = Excursion.generate_qti_manifest(qjson,fileName)
      zos.put_next_entry("imsmanifest.xml")
      zos.print xml_truemanifest

      t.close
    end
  end

  def self.generate_QTITF(qjson,index)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    
    myxml.assessmentItem("xmlns"=>"http://www.imsglobal.org/xsd/imsqti_v2p1", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imsqti_v2p1  http://www.imsglobal.org/xsd/qti/qtiv2p1/imsqti_v2p1.xsd","identifier"=>"choiceMultiple", "title"=>"Prueba", "timeDependent"=>"false", "adaptive" => "false") do
      
      myxml.responseDeclaration("identifier"=>"RESPONSE", "cardinality" => "single", "baseType" => "identifier") do
        
        myxml.correctResponse() do
          if qjson["choices"][index]["answer"] == true 
            myxml.value("A0")
          else
            myxml.value("A1")
          end
        end
        
        myxml.mapping("lowerBound" => "-1", "upperBound"=>"1", "defaultValue"=>"0") do
          if qjson["choices"][index]["answer"] == true
            myxml.mapEntry("mapKey"=>"A0", "mappedValue"=> 1)
            myxml.mapEntry("mapKey"=> "A1", "mappedValue"=> -1)
          else
            myxml.mapEntry("mapKey"=>"A0", "mappedValue"=> -1)
            myxml.mapEntry("mapKey"=> "A1", "mappedValue"=> 1)
          end             
        end

      end

      myxml.outcomeDeclaration("identifier"=>"SCORE", "cardinality"=>"single", "baseType"=>"float") do
      end

      myxml.itemBody() do
        myxml.choiceInteraction("responseIdentifier"=>"RESPONSE", "shuffle" => "false", "maxChoices" => "1", "minChoices"=>"0") do
          myxml.prompt(qjson["question"]["value"]  + ": " + qjson["choices"][index]["value"])
          myxml.simpleChoice("True","identifier"=>"A0")
          myxml.simpleChoice("False","identifier"=>"A1") 
        end
      end

      myxml.responseProcessing()
    end

    return myxml;
  end

  def self.generate_QTIMC(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
      
    nChoices = qjson["choices"].size

    myxml.assessmentItem("xmlns"=>"http://www.imsglobal.org/xsd/imsqti_v2p1", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imsqti_v2p1  http://www.imsglobal.org/xsd/qti/qtiv2p1/imsqti_v2p1.xsd","identifier"=>"choiceMultiple", "title"=>"Prueba", "timeDependent"=>"false", "adaptive"=>"false") do

      identifiers= [] 
      qjson["choices"].each_with_index do |choice,i|
        identifiers.push("A" + i.to_s())
      end

      if qjson["extras"]["multipleAnswer"] == false 
        card = "single"
        maxC = "1"
      else
        card = "multiple"
        maxC = "0"
      end 

      myxml.responseDeclaration("identifier"=>"RESPONSE", "cardinality" => card, "baseType" => "identifier") do
      
        vcont = 0
        myxml.correctResponse() do
          for i in 0..((nChoices)-1)
            if qjson["choices"][i]["answer"] == true 
              myxml.value(identifiers[i])
              vcont = vcont + 1
            end
          end
        end  
        
        myxml.mapping("lowerBound" => "0", "upperBound"=>"1", "defaultValue"=>"0") do
          for i in 0..((nChoices)-1)
            if qjson["choices"][i]["answer"] == true
              mappedV = 1/vcont.to_f
            else
              mappedV = 0.to_f
              #mappedV = -1/(qjson["choices"].size)
            end
            myxml.mapEntry("mapKey"=> identifiers[i], "mappedValue"=> mappedV)
          end
        end 
      end

      myxml.outcomeDeclaration("identifier"=>"SCORE", "cardinality"=>"single", "baseType"=>"float") do
      end
    
      myxml.itemBody() do
        myxml.choiceInteraction("responseIdentifier"=>"RESPONSE", "shuffle"=>"false",  "maxChoices" => maxC, "minChoices"=>"0") do
          myxml.prompt(qjson["question"]["value"])
          for i in 0..((nChoices)-1)
              myxml.simpleChoice(qjson["choices"][i]["value"],"identifier"=> identifiers[i])
          end
        end
      end
          
      myxml.responseProcessing()
    end

    return myxml;
  end

  def self.generate_MoodleQUIZXML(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    myxml.quiz do
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text do
             myxml.text!("Moodle QUIZ XML export")
          end
        end
      end

      myxml.question("type" => "multichoice") do
        myxml.name do
          myxml.text do
            myxml.text!("La pregunta")
          end
        end
      end
    end
  end

  def self.generate_qti_manifest(qjson,fileName)
    identifier = "TmpIMSQTI_" + (Site.current.config["tmpJSONcount"].nil? ? "1" : Site.current.config["tmpJSONcount"].to_s)

    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    
    myxml.manifest("identifier"=>"VISH_QUIZ_" + identifier, "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p2.xsd http://www.imsglobal.org/xsd/imsmd_v1p2 http://www.imsglobal.org/xsd/imsmd_v1p2p2.xsd http://www.imsglobal.org/xsd/imsqti_v2p1 http://www.imsglobal.org/xsd/imsqti_v2p1.xsd", "xmlns" => "http://www.imsglobal.org/xsd/imscp_v1p2","xmlns:imsqti" => "http://www.imsglobal.org/xsd/imsqti_v2p1", "xmlns:imsmd" => "http://www.imsglobal.org/xsd/imsmd_v1p2", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance") do
      
      myxml.metadata do
        myxml.schema("IMS Content")
        myxml.schemaversion("1.2")
        myxml.tag!("imsmd:lom") do
          myxml.tag!("imsmd:general") do
            myxml.tag!("imsmd:title") do
              myxml.tag!("imsmd:langstring", {"xml:lang"=>"en"}) do
                myxml.text!("Content package including QTI v2.1. items")
              end
            end
          end
          myxml.tag!("imsmd:technical") do
            myxml.tag!("imsmd:format") do
              myxml.text!("text/x-imsqti-item-xml")
            end
          end
          myxml.tag!("imsmd:rights") do
            myxml.tag!("imsmd:description") do
              myxml.tag!("imsmd:langstring", {"xml:lang"=>"en"}) do
                myxml.text!("Copyright (C) Virtual Science Hub 2014")
              end
            end
          end
        end
      end
      
      myxml.organizations do
      end

      myxml.resources do
        Excursion.generate_qti_resources(qjson,fileName,myxml)
      end

    end
  end

  def self.generate_mainQTIMC(qjson,fileName)
    resource_identifier = "resource-item-quiz-" + (Site.current.config["tmpJSONcount"].nil? ? "1" : Site.current.config["tmpJSONcount"].to_s)

    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    myxml.assessmentTest("xmlns" => "http://www.imsglobal.org/xsd/imsqti_v2p1", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation" => "http://www.imsglobal.org/xsd/imsqti_v2p1 http://www.imsglobal.org/xsd/imsqti_v2p1.xsd", "identifier" => "TrueFalseTest", "title" => "True False Tests", "toolName"=>"VISH Editor", "toolVersion" => "2.3") do
      myxml.outcomeDeclaration("identifier" => "SCORE", "cardinality" => "single", "baseType" => "integer") do
      end
        if qjson["quiztype"] == "truefalse"
          for i in 0..((qjson["choices"].size)-1)
            myxml.assessmentItemRef("identifier" => resource_identifier + i.to_s, "href" => fileName + "_" + i.to_s + ".xml") do
            end
          end
        end
    end
  end

  def self.generate_qti_resources(qjson,fileName,myxml)
    resource_identifier = "resource-item-quiz-" + (Site.current.config["tmpJSONcount"].nil? ? "1" : Site.current.config["tmpJSONcount"].to_s)

    if qjson["quiztype"] == "truefalse"
      myxml.resource("identifier" => resource_identifier , "type"=>"imsqti_item_xmlv2p1", "href" => fileName + ".xml") do
          myxml.metadata do
            myxml.tag!("imsmd:lom") do
              myxml.tag!("imsmd:general") do
                myxml.tag!("imsmd:title") do
                  myxml.tag!("imsmd:langstring",{"xml:lang"=>"en"}) do
                    myxml.text!("TrueFalse")
                  end
                end
              end
              myxml.tag!("imsmd:technical") do
                myxml.tag!("imsmd:format") do
                  myxml.text!("text/x-imsqti-item-xml")
                end
              end
            end
            myxml.tag!("imsqti:qtiMetadata") do
              myxml.tag!("imsqti:interactionType") do
                myxml.text!("choiceInteraction")
              end
            end
          end
          myxml.file("href" => fileName + ".xml")
        end
      for i in 0..((qjson["choices"].size)-1)
        myxml.resource("identifier" => resource_identifier + i.to_s, "type"=>"imsqti_item_xmlv2p1", "href" => fileName + "_" + i.to_s + ".xml") do
          myxml.metadata do
            myxml.tag!("imsmd:lom") do
              myxml.tag!("imsmd:general") do
                myxml.tag!("imsmd:title") do
                  myxml.tag!("imsmd:langstring",{"xml:lang"=>"en"}) do
                    myxml.text!("TrueFalse")
                  end
                end
              end
              myxml.tag!("imsmd:technical") do
                myxml.tag!("imsmd:format") do
                  myxml.text!("text/x-imsqti-item-xml")
                end
              end
            end
            myxml.tag!("imsqti:qtiMetadata") do
              myxml.tag!("imsqti:interactionType") do
                myxml.text!("choiceInteraction")
              end
            end
          end
          myxml.file("href" => fileName + "_" + i.to_s + ".xml")
        end
      end
    elsif qjson["quiztype"] == "multiplechoice"
      myxml.resource("identifier" => resource_identifier, "type"=>"imsqti_item_xmlv2p1", "href" => fileName + ".xml") do
        myxml.metadata do
          myxml.tag!("imsmd:lom") do
            myxml.tag!("imsmd:general") do
              myxml.tag!("imsmd:title") do
                myxml.tag!("imsmd:langstring",{"xml:lang"=>"en"}) do
                  myxml.text!("MultipleChoice")
                end
              end
            end
            myxml.tag!("imsmd:technical") do
              myxml.tag!("imsmd:format") do
              myxml.text!("text/x-imsqti-item-xml")
              end
            end
          end
          myxml.tag!("imsqti:qtiMetadata") do
            myxml.tag!("imsqti:interactionType") do
              myxml.text!("choiceInteraction")
            end
          end
        end
        myxml.file("href" => fileName + ".xml")
      end
    end
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
      excursion_url = controller.excursion_url(:id => self.id)
      { :id => id,
        :url => excursion_url,
        :title => title,
        :author => author.name,
        :description => description,
        :image => thumbnail_url ? thumbnail_url : Site.current.config[:documents_hostname] + "assets/logos/original/excursion-00.png",
        :views => visit_count,
        :favourites => like_count,
        :number_of_slides => slide_count
      }
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

  def is_mostvaluable?
    is_mve
  end




  private

  def parse_for_meta
    parsed_json = JSON(json)

    activity_object.title = parsed_json["title"] ? parsed_json["title"] : "Title"
    activity_object.description = parsed_json["description"] 
    activity_object.tag_list = parsed_json["tags"]
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
    self.update_column :excursion_type, parsed_json["type"]
    self.update_column :slide_count, parsed_json["slides"].size
    self.update_column :thumbnail_url, parsed_json["avatar"] ? parsed_json["avatar"] : Site.current.config[:documents_hostname] + "assets/logos/original/excursion-00.png"
  end

  def fix_relation_ids_drafts
    if self.draft
      activity_object.relation_ids=[Relation::Private.instance.id]
    else
      activity_object.relation_ids=[Relation::Public.instance.id]
    end
  end
  
end
