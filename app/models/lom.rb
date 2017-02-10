  # encoding: utf-8

class Lom

  ####################
  ## LOM Metadata
  ####################

  # Metadata based on LOM (Learning Object Metadata) standard
  # LOM final draft: http://ltsc.ieee.org/wg12/files/LOM_1484_12_1_v1_Final_Draft.pdf
  def self.generateMetadata(ao, options={})
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

      #Location
      loLocation = ao.getUrl
      loMetadataLocation = ao.getMetadataUrl

      #Identifier
      loId = loLocation
      loIdIsURI = true
      loIdIsURN = false

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
        loId = "urn:ViSH:"+ao.id
      end

      #Language (LO language and metadata language)
      loLanguage = getLoLanguage(ao.language, _LOMschema)
      if loLanguage.nil?
        loLanOpts = {}
      else
        loLanOpts = { :language=> loLanguage }
      end
      metadataLanguage = "en"

      #Author name
      authorName = nil
      unless ao.author.nil? or ao.author.name.nil?
        authorName = ao.author.name
      end

      # loDate 
      # According to ISO 8601 (e.g. 2014-06-23)
      loCreateDate = ao.created_at.strftime("%Y-%m-%d").to_s
      loUpdateDate = ao.updated_at.nil? ? loCreateDate : ao.updated_at.strftime("%Y-%m-%d").to_s

      # loKeywords
      loKeywords = []
      if ao.tags && ao.tags.kind_of?(Array)
        loKeywords = ao.tags
      end

      #Building LOM XML

      myxml.general do
        
        unless loId.nil?
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
          if ao.title
            myxml.string(ao.title, loLanOpts)
          else
            myxml.string("Untitled", :language=> metadataLanguage)
          end
        end

        if loLanguage
          myxml.language(loLanguage)
        end
        
        myxml.description do
          if ao.description
            myxml.string(ao.description, loLanOpts)
          elsif ao.title
            myxml.string(ao.title + ". A resource provided by " + Vish::Application.config.full_domain + ".", :language=> metadataLanguage)
          else
            myxml.string("Resource provided by " + Vish::Application.config.full_domain + ".", :language=> metadataLanguage)
          end
        end
        unless loKeywords.blank?
          loKeywords.each do |tag|
            myxml.keyword do
              myxml.string(tag.to_s, loLanOpts)
            end
          end
        end
      end

      myxml.lifeCycle do
        myxml.version do
          myxml.string("v"+loUpdateDate.gsub("-","."), :language=>metadataLanguage)
        end
        myxml.status do
          myxml.source("LOMv1.0")
          if ao.public_scope?
            myxml.value("published")
          else
            myxml.value("unpublished")
          end
        end

        unless authorName.nil?
          myxml.contribute do
            myxml.role do
              myxml.source("LOMv1.0")
              myxml.value("author")
            end
            authorEntity = generateVCard(authorName)
            myxml.entity(authorEntity)
            
            myxml.date do
              myxml.dateTime(loCreateDate)
              unless _LOMschema == "ODS"
                myxml.description do
                  myxml.string("This date represents the date the resource was first created or published.", :language=> metadataLanguage)
                end
              end
            end
          end
        end
      end

      myxml.metaMetadata do
        myxml.identifier do
          myxml.catalog("URI")
          myxml.entry(loMetadataLocation)
        end
        unless authorName.nil?
          myxml.contribute do
            myxml.role do
              myxml.source("LOMv1.0")
              myxml.value("creator")
            end
            myxml.entity(generateVCard(authorName))
            myxml.date do
              myxml.dateTime(loUpdateDate)
              unless _LOMschema == "ODS"
                myxml.description do
                  myxml.string("This date represents the date the author finished authoring the metadata of the indicated version of the resource.", :language=> metadataLanguage)
                end
              end
            end
          end
        end
        myxml.metadataSchema("LOMv1.0")
        myxml.language(metadataLanguage)
      end

      myxml.technical do
        # myxml.format("text/html") #TODO
        myxml.location(loLocation)
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
      end

      myxml.educational do
        myxml.intendedEndUserRole do
          myxml.source("LOMv1.0")
          myxml.value("learner")
        end
        unless ao.age_range.blank?
          loAgeRange = ao.age_min.to_s + " - " + ao.age_max.to_s
          myxml.typicalAgeRange do
            myxml.string(loAgeRange, :language=> metadataLanguage)
          end
        end
        if loLanguage
          myxml.language(loLanguage)                 
        end
      end

      myxml.rights do
        loLicense = nil
        if ao.should_have_license? and !ao.license.nil?
          loLicense = "License: '" + ao.license_name(metadataLanguage) + "'."
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
      comments = ao.post_activity.comments
      unless comments.blank?
        comments.map{|commentActivity| commentActivity.activity_objects.first}.reject{|c| c.nil? or c.description.blank?}.first(30).each do |comment|
          myxml.annotation do
            unless comment.author.nil? or comment.author.name.blank?
              myxml.entity(generateVCard(comment.author.name))
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

      #Classification (include categories of the ViSH catalogue if any)
      if VishConfig.getAvailableServices.include?("Catalogue")
        unless loKeywords.blank?
          categoryKeywords = Vish::Application.config.catalogue["category_keywords"]
          catalogueKeywords = categoryKeywords.select{|k,v| v.is_a? Array and (v & loKeywords).length > 1}.map{|k,v| k}
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

  def self.getLoLanguage(language, _LOMschema)
    #List of language codes according to ISO-639:1988
    # lanCodes = ["aa","ab","af","am","ar","as","ay","az","ba","be","bg","bh","bi","bn","bo","br","ca","co","cs","cy","da","de","dz","el","en","eo","es","et","eu","fa","fi","fj","fo","fr","fy","ga","gd","gl","gn","gu","gv","ha","he","hi","hr","hu","hy","ia","id","ie","ik","is","it","iu","ja","jw","ka","kk","kl","km","kn","ko","ks","ku","kw","ky","la","lb","ln","lo","lt","lv","mg","mi","mk","ml","mn","mo","mr","ms","mt","my","na","ne","nl","no","oc","om","or","pa","pl","ps","pt","qu","rm","rn","ro","ru","rw","sa","sd","se","sg","sh","si","sk","sl","sm","sn","so","sq","sr","ss","st","su","sv","sw","ta","te","tg","th","ti","tk","tl","tn","to","tr","ts","tt","tw","ug","uk","ur","uz","vi","vo","wo","xh","yi","yo","za","zh","zu"]
    lanCodesMin = I18n.available_locales.map{|i| i.to_s}
    lanCodesMin.concat(["it","pt"]).uniq!

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

end