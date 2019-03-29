# encoding: utf-8

namespace :harvesting do

  #Usage
  #Development:   bundle exec rake harvesting:harvest
  #In production: bundle exec rake harvesting:harvest RAILS_ENV=production
  task :harvest => :environment do
    puts "#####################################"
    puts "Retrieving Learning Objects from other ViSH instances"
    puts "#####################################"
    
    opts = {}
    opts[:harvestingConfig] = YAML.load_file("config/harvesting.yml") rescue {}
    urls = opts[:harvestingConfig]["resources"]
    opts[:harvestingConfig].delete("resources")

    retrieveLOs(urls,opts){ |response|
      puts "\n\n\nHarvesting finished"
      response.each do |msg|
        puts msg
      end
      puts "\n"
    }
  end

  #Usage
  #Development:   bundle exec rake harvesting:retrieveLO
  #In production: bundle exec rake harvesting:retrieveLO RAILS_ENV=production
  task :retrieveLO, [:url] => :environment do |t,args|
    abort("No URL was provided") if args.url.blank?

    opts = {}
    opts[:harvestingConfig] = YAML.load_file("config/harvesting.yml") rescue {}

    retrieveLO(args.url,opts){ |response,success|
      puts "\n\n\nHarvesting finished"
      abort("Error retrieving LO with url: " + args.url) if success.nil?
    }
  end

  def retrieveLOs(urls,opts={},i=0,output=[])
    if !urls.is_a? Array or urls.blank? or urls.select{|s| !s.is_a? String}.length>0
      yield "Invalid urls", nil 
      return
    end

    if i === urls.length
      yield output 
      return
    end

    puts "Retrieving LO with URL: " + (urls[i] or "undefined")
    retrieveLO(urls[i],opts){ |response,success|
      if success.blank?
        output.push("LO with url " + urls[i] + " NOT retrieved. Reason: " + response)
      else
        output.push("LO with url " + urls[i] + " retrieved. LO id: " + response.getGlobalId)
      end
      retrieveLOs(urls,opts,i+1,output){ |output|
        yield output 
      }
    }
  end

  def retrieveLO(url,opts={})
    if url.blank?
      yield "URL is blank", nil 
      return
    end
    opts[:url] = url
    opts[:harvestingConfig] = YAML.load_file("config/harvesting.yml") rescue {} if opts[:harvestingConfig].nil?

    domain = URI.parse(url).host rescue nil
    resourceMatch = url.match(/([a-z]+)\/([0-9]+)$/)
    if domain.blank? or resourceMatch.nil?
      yield "URL is not valid",false 
      return
    end
    
    #Get domain and allowed domains
    domainPort = URI.parse(url).port rescue nil
    domain = domain + ":" + domainPort.to_s unless domainPort.nil? or domainPort===80 or domainPort === 443
    allowedDomains = [domain]
    allowedDomains = (allowedDomains + opts[:harvestingConfig]["allowed_domains"].select{|d| d.is_a? String}).uniq if opts[:harvestingConfig]["allowed_domains"].is_a? Array
    allowedDomains = (allowedDomains + opts[:harvestingConfig]["allowed_code_domains"].select{|d| d.is_a? String}).uniq if opts[:harvestingConfig]["allowed_code_domains"].is_a? Array
    allowedDomains.each do |d|
      allowedDomains.push("www." + d) unless d.include?("www.")
    end
    allowedDomains.uniq!
    opts[:domain] = domain
    opts[:allowedDomains] = allowedDomains

    jsonURL = url + ".json" 
    resourceId = resourceMatch[1].capitalize.singularize + ":" + resourceMatch[2] + "@" + domain
    searchURL = "http://" + domain + "/apis/search?id=" + resourceId
    opts[:universalResourceId] = resourceId
    opts[:searchURL] = searchURL

    RestClient::Request.execute(
      :method => :get,
      :url => jsonURL,
      :timeout => 8, 
      :open_timeout => 8
    ){ |response|
      if response.code === 200
        lojson = JSON(response) rescue nil
        if lojson.nil?
          yield "Invalid response",false 
          return
        end
        opts[:json] = lojson

        afterRetrieveLO(opts){ |lo,success|
          yield lo, success 
          return
        }
      else
        yield "Response with invalid code",false 
        return
      end
    }
  end

  def afterRetrieveLO(opts)
    RestClient::Request.execute(
      :method => :get,
      :url => opts[:searchURL],
      :timeout => 8, 
      :open_timeout => 8
    ){ |response|
      searchjson = {}
      searchjson = JSON(response) rescue {} if response.code === 200
      opts[:searchjson] = searchjson
      createLO(opts){ |lo|
        if lo.nil?
          yield "LO could not be created", false
        else
          yield lo, true
        end
      }
    }
  end

  def createLO(opts)
    unless opts[:json].is_a? Hash
      yield nil 
      return nil
    end

    # Set a specific owner
    opts[:owner] = User.find_by_email( opts[:harvestingConfig]["owner_email"]).actor rescue nil
    if opts[:owner].nil?
      yield nil 
      return nil
    end

    resourceType = (opts[:json]["type"] || opts[:searchjson]["type"])
    resourceType = resourceType.underscore if resourceType.is_a? String
    opts[:resourceType] = resourceType

    case resourceType
    when "presentation"
      createVEPresentation(opts){ |lo|
        yield lo
      }
    when "scormpackage","webapp","imscppackage","zipfile","link","officedoc","swf","picture","video","audio","document"
      createResource(opts){ |lo|
        yield lo
      }
    when "category"
      createCategory(opts){ |lo|
        yield lo
      }
    else
      #Unrecognized type
      yield nil
    end
  end

  def createResource(opts)
    case opts[:resourceType]
    when "scormpackage","webapp","imscppackage"
      r = Zipfile.new
    else
      rClass = opts[:resourceType].capitalize.constantize rescue nil
      if rClass.nil?
        yield nil 
        return nil 
      end
      r = rClass.new
    end

    searchjson = opts[:searchjson]
    r.title = searchjson["title"] unless searchjson["title"].blank?
    r.description = searchjson["description"] unless searchjson["description"].blank?
    r.language = searchjson["language"] unless searchjson["language"].blank?

    #Age range
    if searchjson["age_range"].is_a? String and !searchjson["age_range"].blank? 
      ageRange = searchjson["age_range"].split("-")
      if ageRange.length === 2 and ageRange.map{|s| s.to_i.to_s === s.to_s}.uniq === [true]
        r.age_min = ageRange[0].to_i
        r.age_max = ageRange[1].to_i
      end
    end
    
    #Tags
    r.tag_list = (parseTags(searchjson["tags"],opts[:harvestingConfig]["additional_tags"]))

    #Avatar
    unless searchjson["avatar_url"].blank?
      avatarFile = downloadFile(searchjson["avatar_url"])
      r.avatar = avatarFile unless avatarFile.nil?
    end

    r.owner_id = opts[:owner].id
    r.author_id = opts[:owner].id
    r.user_author_id = opts[:owner].id
    if [0,1].include?(opts[:scope])
      r.scope = opts[:scope]
    else
      r.scope = 0
    end
    
    #Author
    authorName = ""
    if !searchjson["original_author"].blank?
      authorName = searchjson["original_author"]
    elsif !searchjson["author"].blank?
      authorName = searchjson["author"]
    end

    #License
    if searchjson["license_key"].is_a? String or searchjson["license"].is_a? String
      if searchjson["license_key"].is_a? String
        license = License.find_by_key(searchjson["license_key"])
      elsif searchjson["license"].is_a? String
        license = License.getLicenseWithName(searchjson["license"])
      end
      license = License.find_by_key("other") if license.nil?
      r.license = license
      r.license_custom = searchjson["license"] if license.key === "other" and searchjson["license"].is_a? String
    else
      #No license data
      #Use default
    end
    r.license_attribution = authorName + " (" + opts[:url] + ")"
    r.license_attribution = r.license_attribution + ". " + searchjson["license_attribution"] unless searchjson["license_attribution"].blank?

    #File
    unless searchjson["file_url"].blank?
      file = downloadFile(searchjson["file_url"])
      r.file = file unless file.nil?
    end

    unless searchjson["created_at"].blank?
      parsedTime = Time.parse(searchjson["created_at"] + " 12:00")
      r.created_at = parsedTime unless parsedTime.nil?
    end

    unless searchjson["reviewers_qscore"].blank?
      r.reviewers_qscore = BigDecimal(searchjson["reviewers_qscore"],6) if searchjson["reviewers_qscore"].to_s.to_f === searchjson["reviewers_qscore"]
    end
    unless searchjson["users_qscore"].blank?
      r.users_qscore = BigDecimal(searchjson["users_qscore"],6) if searchjson["users_qscore"].to_s.to_f === searchjson["users_qscore"]
    end

    #For links
    r.url = searchjson["url_full"] if r.respond_to?("url") and !searchjson["url_full"].blank? 
    if r.respond_to?("is_embed")
      if [true, false].include? opts[:json]["is_embed"]
        r.is_embed = opts[:json]["is_embed"]
      else
        r.is_embed = true
      end
    end
     
    r.valid?
    if r.errors.full_messages.length === 1 and r.errors.full_messages[0].include?("same title")
      prefix = r.class.last.nil? ? (r.class.count+1).to_s : r.class.last.id.to_s
      r.title = r.title + "-" + prefix
    end

    begin
      r.save!
      if ["scormpackage","webapp","imscppackage"].include? opts[:resourceType]
        newR = r.getResourceAfterSave
        raise "Invalid resource" if newR.is_a? String
      else
        newR = r
      end
      afterCreateLO(newR,opts){ |lo|
        yield lo 
      }
    rescue => e
      yield nil 
    end
  end

  def afterCreateLO(lo,opts)
    unless lo.nil?
      #Harvested
      lo.activity_object.update_column :harvested,true

      #Quality metrics
      lo.calculate_qscore

      #Popularity metrics
      searchjson = opts[:searchjson]
      lo.activity_object.update_column :visit_count,searchjson["visit_count"] if searchjson["visit_count"].is_a? Integer
      lo.activity_object.update_column :download_count,searchjson["download_count"] if searchjson["download_count"].is_a? Integer

      #Category
      unless opts[:harvestingConfig]["category_id"].blank?
        c = Category.find_by_id(opts[:harvestingConfig]["category_id"].to_i)
        unless c.nil?
          ao = lo.activity_object
          if ao.object_type === "Category"
            lo.parent = c
            lo.save
          else
            c.insertPropertyObject(lo.activity_object)
          end
        end       
      end
    end

    yield lo 
  end

  def createCategory(opts)
    #Create category

    createResource(opts){ |category|
      if category.nil?
        yield nil 
        return nil
      end
      puts "##############################}"
      puts "Category created with id: " + category.id.to_s
      puts "##############################}"

      if opts[:json]["elements"].blank? or !opts[:json]["elements"].is_a? Array
        yield category 
        return category
      end

      #Create the resources of the retrieved category and included them in the local created category
      resourceURLs = []
      opts[:json]["elements"].each do |el|
        elMatch = el.match(/([aA-zZ]+):([0-9]+)$/)
        next if elMatch.blank? or elMatch[1].blank? or elMatch[2].blank?
        universalResourceId = el + "@" + opts[:domain]
        resourceURL = ActivityObject.getUrlForUniversalId(universalResourceId)
        next if resourceURL.blank?
        resourceURLs.push(resourceURL)
      end

      newOpts = Marshal.load(Marshal.dump(opts))
      newOpts[:harvestingConfig]["category_id"] = category.id.to_s

      puts "\n\n\nHarvesting resources of category " + opts[:url] + "."
      retrieveLOs(resourceURLs,newOpts){ |response|
        puts "\n\n\nHarvesting of resources of category " + opts[:url] + " finished. Results are shown below."
        response.each do |msg|
          puts msg
        end
        puts "\n"

        yield category 
      }
    }
  end

  def createVEPresentation(opts)
    json = opts[:json]
    searchjson = opts[:searchjson]

    ex = Excursion.new
    json["draft"] = false
    sourceAuthor = json["author"] || {}
    json["author"] = {"name":opts[:owner].name,"vishMetadata":{"id":opts[:owner].id}}
    json["vishMetadata"] = json["vishMetadata"] || {}
    json["vishMetadata"]["draft"] = "false"
    json["vishMetadata"]["released"] = "true"
    json["vishMetadata"]["name"] = "ViSH"
    
    #Tags
    json["tags"] = parseTags(json["tags"],opts[:harvestingConfig]["additional_tags"])

    #Avatar
    createAvatar(json["avatar"],opts){ |avatarURL|
      json["avatar"] = avatarURL
      
      #Retrieve resources of the VE presentation
      resourceURLs = []

      resourceURLs = resourceURLs + VishEditorUtils.getResources(json, ["image","object","video","audio"])
      #Get resources embedded inside text and quiz resources
      VishEditorUtils.getResources(json, ["text","quiz"]).each do |string|
        resourceURLs = resourceURLs + string.scan(Regexp.new("http[s]?://[a-z0-9.]+/[a-z]+/[a-z0-9.]+"))
      end
      resourceURLs = resourceURLs.uniq.select{|r| URI.parse(r).kind_of?(URI::HTTP)}
      resourceURLs = resourceURLs.select{|r| opts[:allowedDomains].include?(URI.parse(r).host)} #Retrieve only resources stored in the foreign vish instance or allowed domains
      resourceURLs = resourceURLs.map{|string| 
        if string.ends_with?(")")
          string = string[0...-1]
        end
        if File.extname(string).include?("?")
          string = string.split("?")[0] unless File.extname(string).include?("?style=")
        end
        string
      }
      #For videos from ViSH instances with multiple sources, only take into account mp4 files (and png files for posters)
      resourceURLs = resourceURLs.reject{ |string| 
        opts[:allowedDomains].include?(URI.parse(string).host) and string.include?("/videos/") and (!string.include?(".mp4") and !string.include?(".png"))
      }

      createPrivateResources(resourceURLs,opts){ |resourceURLmapping|
        resourceURLmapping.each do |oldURL,newURL|
          json = replaceStringInHash(json,oldURL,newURL)
        end
        json = replaceSourcesInHash(json,resourceURLmapping.values,opts)

        ex.json = json.to_json
        ex.owner_id = opts[:owner].id
        ex.author_id = opts[:owner].id
        ex.user_author_id = opts[:owner].id
        ex.license_attribution = (sourceAuthor["name"] || "") + " (" + opts[:url] + ")"

        unless searchjson["created_at"].blank?
          parsedTime = Time.parse(searchjson["created_at"] + " 12:00")
          ex.created_at = parsedTime unless parsedTime.nil?
        end

        unless searchjson["reviewers_qscore"].blank?
          ex.reviewers_qscore = BigDecimal(searchjson["reviewers_qscore"],6) if searchjson["reviewers_qscore"].to_s.to_f === searchjson["reviewers_qscore"]
        end
        unless searchjson["users_qscore"].blank?
          ex.users_qscore = BigDecimal(searchjson["users_qscore"],6) if searchjson["users_qscore"].to_s.to_f === searchjson["users_qscore"]
        end

        begin
          ex.save!
          afterCreateLO(ex,opts){ |lo|
            yield lo 
          }
        rescue => e
          yield nil 
        end
      }
    }
  end

  def createPrivateResources(resourceURLs,opts,i=0,resourceURLmapping={})
    if i === resourceURLs.length
      yield resourceURLmapping 
      return resourceURLmapping
    end

    if resourceURLmapping[resourceURLs[i]].blank?
      createPrivateResource(resourceURLs[i],opts){ |resourceURL|
        resourceURLmapping[resourceURLs[i]] = resourceURL unless resourceURL.blank?
        createPrivateResources(resourceURLs,opts,i+1,resourceURLmapping){ |rmapping|
          yield rmapping 
        }
      }
    else
      createPrivateResources(resourceURLs,opts,i+1,resourceURLmapping){ |rmapping|
        yield rmapping 
      }
    end
  end

  def createPrivateResource(resourceURL,opts)
    if opts[:allowedDomains].include?(URI.parse(resourceURL).host)
      newResourceURL = nil
      resourceMatch = resourceURL.match((/([a-z]+)\/([0-9]+)(.[a-z]+)?$/))
      if !resourceMatch.nil?
        #Resources from ViSH instances. Retrieve in the same way as other ViSH resources but with scope=1.
        newResourceURL = resourceURL
        newResourceURL = newResourceURL.gsub(resourceMatch[3],"") unless resourceMatch[3].blank?
        newResourceURL = newResourceURL.gsub("www.","") if !opts[:domain].include?("www.")
      else
        webappMatch = resourceURL.match((/webappscode\/([0-9]+)/))
        if !webappMatch.nil?
          newResourceURL = "http://" + opts[:domain] + "/webapps/" + webappMatch[1]
        else
          scormpackageMatch = resourceURL.match((/\/scorm\/packages\/([0-9]+)\/vishubcode_scorm_wrapper.html/))
          if !scormpackageMatch.nil?
            newResourceURL = "http://" + opts[:domain] + "/scormfiles/" + scormpackageMatch[1]
          end
        end
      end

      unless newResourceURL.blank?
        newOpts = Marshal.load(Marshal.dump(opts))
        newOpts[:scope] = 1
        newOpts[:harvestingConfig].delete("category_id") #Private resources should not be stored in categories

        if newResourceURL.include?("excursions")
          #Prevent loops
          yield nil 
          return nil
        end

        retrieveLO(newResourceURL,newOpts){ |lo,success|
          if success.blank?
            yield nil 
            return
          else
            #Return LO URL
            loURL = lo.getFullUrl(nil) rescue nil
            yield loURL 
            return
          end
        }
      end
    end

    #Retrieve it as foreign resources
    extension = File.extname(resourceURL).split("?")[0]
    opts[:extension] = extension
    case extension
    when ".png",".jpeg",".jpg", ".gif", ".tiff", ".bmp", ".svg"
      createPrivatePicture(resourceURL,opts){ |resourceURL|
        yield resourceURL 
      }
    when ".mp4",".webm"
      createPrivateObject("video",resourceURL,opts){ |resourceURL|
        yield resourceURL 
      }
    when ".mp3", ".wav", ".webma"
      createPrivateObject("audio",resourceURL,opts){ |resourceURL|
        yield resourceURL 
      }
    when ".swf"
      createPrivateObject("swf",resourceURL,opts){ |resourceURL|
        yield resourceURL 
      }
    when ".pdf"
      createPrivateObject("officedoc",resourceURL,opts){ |resourceURL|
        yield resourceURL 
      }
    when ".full"
      yield nil 
    when ".html"
      yield nil 
    when "", ".org",".es",".com"
      #Do nothing
      yield nil 
    else
      # puts "#########################################################################"
      # puts "#########################################################################"
      # puts "Unrecognized extension: " + extension
      # puts "#########################################################################"
      # puts "#########################################################################"
      yield nil 
    end
  end

  def createAvatar(avatarURL,opts)
    newOpts = Marshal.load(Marshal.dump(opts))
    newOpts[:avatar] = true
    createPrivatePicture(avatarURL,newOpts){ |resourceURL|
      yield resourceURL 
    }
  end

  def createPrivatePicture(pictureURL,opts)
    system("rm -rf tmp/vishHarvesting")
    system("mkdir -p tmp/vishHarvesting")

    pictureFile = downloadFile(pictureURL)
    
    if pictureFile.nil?
      unless opts[:avatar]===true
        yield nil 
        return nil
      end
      pictureFile = File.open(Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png', "r")
    end

    pic = Picture.new
    pic.title = File.basename(pictureFile)
    pic.owner_id = opts[:owner].id
    pic.author_id = opts[:owner].id
    pic.user_author_id = opts[:owner].id
    pic.scope = 1
    pic.harvested = true
    pic.file = pictureFile

    begin
      pic.save!
    rescue => e
      #Corrupted (but downloaded) images
      unless opts[:avatar]===true
        yield nil 
        return nil 
      end
      pic.file = File.open(Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png', "r")
      pic.save!
    end

    if opts[:avatar]===true
      resourceURL = pic.getAvatarUrl
    else
      resourceURL = pic.getFullUrl(nil)
    end

    yield resourceURL 
  end

  def createPrivateObject(type,resourceURL,opts)
    system("rm -rf tmp/vishHarvesting")
    system("mkdir -p tmp/vishHarvesting")

    objectFile = downloadFile(resourceURL)
    if objectFile.nil?
      yield nil 
      return nil
    end

    begin
      r = type.downcase.capitalize.constantize.new
    rescue
      r = Document.new
    end

    r.title = File.basename(objectFile)
    r.owner_id = opts[:owner].id
    r.author_id = opts[:owner].id
    r.user_author_id = opts[:owner].id
    r.scope = 1
    r.harvested = true
    r.file = objectFile

    begin
      r.save!
      yield r.getDownloadUrl(nil) 
    rescue => e
      yield nil 
    end
  end



  #Utils

  def downloadFile(fileURL)
    #Download file
    system("rm -rf tmp/vishHarvesting")
    system("mkdir -p tmp/vishHarvesting")

    begin
      fileURI = URI.parse(fileURL)
      fileName = File.basename(fileURI.path)
      filePath = "tmp/vishHarvesting/" + fileName
      fileURL = URI.encode(fileURL)
      command = "wget " + fileURL + " --output-document='" + filePath + "'"
      system(command)
      file = File.new(filePath)
    rescue => e
      file = nil
    end
    return file
  end

  def replaceStringInHash(h,oldString,newString)
    h.each do |key,value|
      if h[key].is_a? Hash
        h[key] = replaceStringInHash(h[key],oldString,newString)
      elsif h[key].is_a? Array
        h[key] = h[key].map{ |el|
          if el.is_a? Hash
            replaceStringInHash(el,oldString,newString)
          elsif el.is_a? String
            el.gsub(oldString,newString)
          end
        }
      elsif h[key].is_a? String
        h[key] = value.gsub(oldString,newString)
      end
    end
    return h
  end

  def replaceSourcesInHash(h,localSources,opts)
    h.delete("vishubPdfexId") if h.key?("vishubPdfexId")

    if h.key?("sources") and (h["type"]==="video" or h["type"]==="audio")
      sources = JSON.parse(h["sources"]) rescue nil
      unless sources.blank?
        localSource = sources.map.select{|src| localSources.include?(src["src"])}.first["src"] rescue nil
        unless localSource.blank?
          sources = sources.map{|src|
            if src["src"]!=localSource and (!VishConfig.getAvailableServices.include? "MediaConversion" or opts[:harvestingConfig]["mediaconversion"] === false)
              nil #Remove no local sources
            else
              localSourceExtension = File.extname(localSource).split("?")[0]
              if src["src"].include?(".mp4")
                src["type"] = "video/mp4"
                src["src"] = localSource.gsub(localSourceExtension,".mp4")
              elsif src["src"].include?(".webma")
                src["type"] == "audio/webma"
                src["src"] = localSource.gsub(localSourceExtension,".webma")
              elsif src["src"].include?(".webm")
                if h["type"]==="video"
                  src["type"] = "video/webm"
                else
                  src["type"] = "audio/webm"
                end
                src["src"] = localSource.gsub(localSourceExtension,".webm")
              elsif src["src"].include?(".flv")
                src["type"] == "video/x-flv"
                src["src"] = localSource.gsub(localSourceExtension,".flv")
              elsif src["src"].include?(".mp3")
                src["type"] == "audio/mpeg"
                src["src"] = localSource.gsub(localSourceExtension,".mp3")
              elsif src["src"].include?(".wav")
                src["type"] == "audio/wav"
                src["src"] = localSource.gsub(localSourceExtension,".wav")
              else
                src = nil
              end
              src
            end
          }
          h["sources"] = sources.compact.to_json
        end
      end
    end

    h.each do |key,value|
      if h[key].is_a? Hash
        h[key] = replaceSourcesInHash(h[key],localSources,opts)
      elsif h[key].is_a? Array
        h[key] = h[key].map{ |el|
          if el.is_a? Hash
            replaceSourcesInHash(el,localSources,opts)
          else
            el
          end
        }
      end
    end
    return h
  end

  def parseTags(tags,additionalTags)
    return [] unless tags.is_a? Array
    tags = tags.uniq.first(Vish::Application.config.tagsSettings["maxTags"])

    #Additional tags
    if additionalTags.is_a? Array and additionalTags.length > 0
      #Limit number of additional tags if necessary
      additionalTags = additionalTags.uniq.first(Vish::Application.config.tagsSettings["maxTags"])
      #Prevent tag repetition 
      tags = (tags - additionalTags)

      #Check if existing tags need to be removed
      atL = additionalTags.length
      tL = tags.length
      if tL+atL > Vish::Application.config.tagsSettings["maxTags"]
        #Remove existing tags to add the new ones
        tagsToRemove = atL+tL-Vish::Application.config.tagsSettings["maxTags"]
        #Remove tags that do not correspond to a category first
        (tags - Vish::Application.config.catalogue["categories"]).sample(tagsToRemove).each do |tagToRemove|
          tags = tags.reject{|tag| tag === tagToRemove}
        end
        #Then, remove any existing tag if necessary
        tL = tags.length
        tagsToRemove = [atL+tL-Vish::Application.config.tagsSettings["maxTags"],0].max
        if tagsToRemove > 0
          tags.sample(tagsToRemove).each do |tagToRemove|
            tags = tags.reject{|tag| tag === tagToRemove}
          end
        end
      end
      tags = (tags+additionalTags).first(Vish::Application.config.tagsSettings["maxTags"])
    end

    tags = tags.map{|tL| tL.gsub(" ","_")} if Vish::Application.config.tagsSettings["triggerKeys"].include?("space")
    tags = tags.map{|tL| tL.gsub(",","_")} if Vish::Application.config.tagsSettings["triggerKeys"].include?("comma")
    return tags
  end

end