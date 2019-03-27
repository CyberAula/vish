# encoding: utf-8

namespace :harvesting do

  #Usage
  #Development:   bundle exec rake harvesting:harvest
  #In production: bundle exec rake harvesting:harvest RAILS_ENV=production
  task :harvest => :environment do
    puts "#####################################"
    puts "Retrieving Learning Objects from other ViSH instances"
    puts "#####################################"
    harvestingConfig = YAML.load_file("config/harvesting.yml") rescue {}
    urls = harvestingConfig["resources"]
    retrieveLOs(urls,harvestingConfig){ |response,code|
      puts "Finish"
    }
  end

  #Usage
  #Development:   bundle exec rake harvesting:retrieveLO
  #In production: bundle exec rake harvesting:retrieveLO RAILS_ENV=production
  task :retrieveLO, [:url] => :environment do |t,args|
    abort("No URL was provided") if args.url.blank?
    retrieveLO(args.url){ |response,code|
      abort("Error retrieving LO with url: " + args.url) if code.nil?
    }
    puts "Finish"
  end

  def retrieveLOs(urls,harvestingConfig=nil,i=0)
    if !urls.is_a? Array or urls.blank? or urls.select{|s| !s.is_a? String}.length>0
      yield "Invalid urls", nil if block_given?
      return
    end

    if i === urls.length
      yield "Finish", true if block_given?
      return
    end

    puts "Retrieving LO with URL: " + (urls[i] or "undefined")
    retrieveLO(urls[i],harvestingConfig){ |response,code|
      if code.blank?
        puts "LO NOT retrieved. Reason: " + response
      else
        puts "LO succesfully retrieved. LO id: " + response.getGlobalId
      end
      retrieveLOs(urls,harvestingConfig,i+1)
    }
  end

  def retrieveLO(url,harvestingConfig=nil)
    if url.blank?
      yield "URL is blank", nil if block_given?
      return
    end

    domain = URI.parse(url).host rescue nil
    resourceMatch = url.match(/([a-z]+)\/([0-9]+)$/)
    if domain.blank? or resourceMatch.nil?
      yield "URL is not valid", nil if block_given?
      return
    end
    jsonURL = url + ".json" 
    resourceId = resourceMatch[1].capitalize.singularize + ":" + resourceMatch[2] + "@" + domain
    searchURL = "http://" + domain + "/apis/search?id=" + resourceId

    RestClient::Request.execute(
      :method => :get,
      :url => jsonURL,
      :timeout => 8, 
      :open_timeout => 8
    ){ |response|
      if response.code === 200
        lojson = JSON(response) rescue nil
        if lojson.nil?
          yield "Invalid response",nil if block_given?
          return
        end

        afterRetrieveLO(lojson,url,searchURL,harvestingConfig){ |lo,code|
          yield lo, code if block_given?
          return
        }
      else
        yield "Response with invalid code", nil if block_given?
        return
      end
    }
  end

  def afterRetrieveLO(lojson,url,searchURL,harvestingConfig)
      RestClient::Request.execute(
        :method => :get,
        :url => searchURL,
        :timeout => 8, 
        :open_timeout => 8
      ){ |response|
        searchjson = {}
        if response.code === 200
          searchjson = JSON(response) rescue {}
        end
        lo = createLO(lojson,searchjson,url,harvestingConfig)
        if lo.nil?
          yield "LO could not be created", nil if block_given?
          return
        end
        yield lo,true if block_given?
      }
  end

  def createLO(json,searchjson,url,harvestingConfig=nil)
    return nil unless json.is_a? Hash
    harvestingConfig = YAML.load_file("config/harvesting.yml") rescue {} if harvestingConfig.nil?

    # Set a specific owner
    owner = User.find_by_email(harvestingConfig["owner_email"]).actor rescue nil
    return nil if owner.nil?

    resourceType = (json["type"] || searchjson["type"])
    case resourceType
    when "presentation"
      lo = createVEPresentation(json,searchjson,owner,url,harvestingConfig)
    when "scormpackage","webapp","imscppackage","Zipfile"
      lo = createApp(json,searchjson,owner,url,harvestingConfig,resourceType)
    else
    end

    unless lo.nil?
      #Quality metrics
      lo.calculate_qscore

      #Popularity metrics
      lo.activity_object.update_column :visit_count,searchjson["visit_count"] if searchjson["visit_count"].is_a? Integer
      lo.activity_object.update_column :download_count,searchjson["download_count"] if searchjson["download_count"].is_a? Integer
    end

    return lo
  end

  def createApp(json,searchjson,owner,url,harvestingConfig,appType)
    case appType
    when "scormpackage","webapp","imscppackage","Zipfile"
      app = Zipfile.new
    else
    end

    app.title = searchjson["title"] unless searchjson["title"].blank?
    app.description = searchjson["description"] unless searchjson["description"].blank?
    app.language = searchjson["language"] unless searchjson["language"].blank?

    #Age range
    if searchjson["age_range"].is_a? String and !searchjson["age_range"].blank? 
      ageRange = searchjson["age_range"].split("-")
      if ageRange.length === 2 and ageRange.map{|s| s.to_i.to_s === s.to_s}.uniq === [true]
        app.age_min = ageRange[0].to_i
        app.age_max = ageRange[1].to_i
      end
    end
    
    #Tags
    app.tag_list = (parseTags(searchjson["tags"],harvestingConfig["additional_tags"]))

    #Avatar
    unless searchjson["avatar_url"].blank?
      avatarFile = downloadFile(searchjson["avatar_url"])
      app.avatar = avatarFile unless avatarFile.nil?
    end

    app.owner_id = owner.id
    app.author_id = owner.id
    app.user_author_id = owner.id
    app.scope = 0

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
        license = License.where(:key => searchjson["license_key"])
      elsif searchjson["license"].is_a? String
        license = License.getLicenseWithName(searchjson["license"])
      end
      license = License.find_by_key("other") if license.nil?
      app.license = license
      app.license_custom = searchjson["license"] if license.key === "other" and searchjson["license"].is_a? String
    else
      #No license data
      #Use default
    end
    app.license_attribution = authorName + " (" + url + ")"
    app.license_attribution = app.license_attribution + ". " + searchjson["license_attribution"] unless searchjson["license_attribution"].blank?

    #File
    unless searchjson["file_url"].blank?
      file = downloadFile(searchjson["file_url"])
      app.file = file unless file.nil?
    end

    unless searchjson["created_at"].blank?
      parsedTime = Time.parse(searchjson["created_at"])
      app.created_at = parsedTime unless parsedTime.nil?
    end

    unless searchjson["reviewers_qscore"].blank?
      app.reviewers_qscore = BigDecimal(searchjson["reviewers_qscore"],6) if searchjson["reviewers_qscore"].to_s.to_f === searchjson["reviewers_qscore"]
    end
    unless searchjson["users_qscore"].blank?
      app.users_qscore = BigDecimal(searchjson["users_qscore"],6) if searchjson["users_qscore"].to_s.to_f === searchjson["users_qscore"]
    end

    begin
      app.save!
      if ["scormpackage","webapp","imscppackage"].include? appType
        newApp = app.getResourceAfterSave
        raise "Invalid app" if newApp.is_a? String
      else
        newApp = app
      end
      return newApp
    rescue => e
      return nil
    end
  end


  def createVEPresentation(json,searchjson,owner,url,harvestingConfig)
    ex = Excursion.new
    json["draft"] = false
    sourceAuthor = json["author"] || {}
    json["author"] = {"name":owner.name,"vishMetadata":{"id":owner.id}}
    json["vishMetadata"] = json["vishMetadata"] || {}
    json["vishMetadata"]["draft"] = "false"
    json["vishMetadata"]["released"] = "true"
    json["vishMetadata"]["name"] = "ViSH"
    
    #Tags
    json["tags"] = parseTags(json["tags"],harvestingConfig["additional_tags"])

    #Avatar
    avatarURL = createAvatar(json["avatar"],owner)
    json["avatar"] = avatarURL
    
    #Retrieve resources of the VE presentation
    resourceURLmapping = {}
    resourceURLs = []
    domain = URI.parse(url).host
    resourceURLs = resourceURLs + VishEditorUtils.getResources(json, ["image","object","video","audio"])
    #Get resources embedded inside text and quiz resources
    VishEditorUtils.getResources(json, ["text","quiz"]).each do |string|
      resourceURLs = resourceURLs + string.scan(Regexp.new("http[s]?://[a-z0-9.]+/[a-z]+/[a-z0-9.]+"))
    end
    resourceURLs = resourceURLs.uniq.select{|r| URI.parse(r).kind_of?(URI::HTTP)}
    resourceURLs = resourceURLs.select{|r| URI.parse(r).host === domain or URI.parse(r).host === ("www." + domain)}.uniq #Retrieve only resources stored in the foreign vish instance
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
      URI.parse(string).host === domain and string.include?("/videos/") and (!string.include?(".mp4") and !string.include?(".png"))
    }
    resourceURLs.each do |r|
      next unless resourceURLmapping[r].blank?
      resourceURL = createResource(r,owner)
      resourceURLmapping[r] = resourceURL unless resourceURL.blank?
    end
    resourceURLmapping.each do |oldURL,newURL|
      json = replaceStringInHash(json,oldURL,newURL)
    end

    json = replaceSourcesInHash(json,resourceURLmapping.values,harvestingConfig)
    
    ex.json = json.to_json
    ex.owner_id = owner.id
    ex.author_id = owner.id
    ex.user_author_id = owner.id
    ex.license_attribution = (sourceAuthor["name"] || "") + " (" + url + ")"

    unless searchjson["created_at"].blank?
      parsedTime = Time.parse(searchjson["created_at"])
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
      return ex
    rescue => e
      return nil
    end
  end

  def createResource(resourceURL,owner)
    extension = File.extname(resourceURL).split("?")[0]
    case extension
    when ".png",".jpeg",".jpg", ".gif", ".tiff", ".bmp", ".svg"
      return createPicture(resourceURL,owner)
    when ".mp4",".webm"
      return createObject("Video",resourceURL,owner)
    when ".mp3", ".wav", ".webma"
      return createObject("Audio",resourceURL,owner)
    when ".swf"
      return createObject("SWF",resourceURL,owner)
    when ".pdf"
      return createObject("Officedoc",resourceURL,owner)
    when ""
      #Do nothing
    else
      puts "#########################################################################"
      puts "#########################################################################"
      puts "Unrecognized extension: " + extension
      puts "#########################################################################"
      puts "#########################################################################"
    end
    return nil
  end

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

  def createAvatar(avatarURL,owner)
    createPicture(avatarURL,owner,true)
  end

  def createPicture(pictureURL,owner,avatar=false)
    system("rm -rf tmp/vishHarvesting")
    system("mkdir -p tmp/vishHarvesting")

    begin
      pictureURI = URI.parse(pictureURL)
      fileName = File.basename(pictureURI.path)
      filePath = "tmp/vishHarvesting/" + fileName
      pictureURL = URI.encode(pictureURL) unless pictureURL.include?("?style=170x127%23")
      command = "wget " + pictureURL + " --output-document='" + filePath + "'"
      system(command)
    rescue => e
      filePath = nil
    end
    
    if filePath.nil? or !File.exist?(filePath) or File.zero?(filePath)
      return nil unless avatar===true
      filePath = Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png'
    end

    pic = Picture.new
    pic.title = fileName
    pic.owner_id = owner.id
    pic.author_id = owner.id
    pic.user_author_id = owner.id
    pic.scope = 1
    pic.file = File.open(filePath, "r")

    begin
      pic.save!
    rescue => e
      #Corrupted (but downloaded) images
      return nil unless avatar===true
      filePath = Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png'
      pic.file = File.open(filePath, "r")
      pic.save!
    end

    if avatar===true
      return pic.getAvatarUrl
    else
      return pic.getFullUrl(nil)
    end
  end

  def createObject(type,resourceURL,owner)
    system("rm -rf tmp/vishHarvesting")
    system("mkdir -p tmp/vishHarvesting")

    begin
      resourceURI = URI.parse(resourceURL)
      fileName = File.basename(resourceURI.path)
      filePath = "tmp/vishHarvesting/" + fileName
      resourceURL = URI.encode(resourceURL)
      command = "wget " + resourceURL + " --output-document='" + filePath + "'"
      system(command)
    rescue => e
      filePath = nil
    end
    return nil if filePath.nil? or !File.exist?(filePath) or File.zero?(filePath)

    if type === "Video"
      r = Video.new
    elsif type === "Audio"
      r = Audio.new
    elsif type === "SWF"
      r = Swf.new
    elsif type === "Officedoc"
      r = Officedoc.new
    else
      r = Document.new
    end
    r.title = fileName
    r.owner_id = owner.id
    r.author_id = owner.id
    r.user_author_id = owner.id
    r.scope = 1
    r.file = File.open(filePath, "r")

    begin
      r.save!
    rescue => e
      return nil
    end

    return r.getDownloadUrl(nil)
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

  def replaceSourcesInHash(h,localSources,harvestingConfig)
    if h.key?("sources") and (h["type"]==="video" or h["type"]==="audio")
      sources = JSON.parse(h["sources"]) rescue nil
      unless sources.blank?
        localSource = sources.map.select{|src| localSources.include?(src["src"])}.first["src"] rescue nil
        unless localSource.blank?
          sources = sources.map{|src|
            if src["src"]!=localSource and (!VishConfig.getAvailableServices.include? "MediaConversion" or harvestingConfig["mediaconversion"] === false)
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
        h[key] = replaceSourcesInHash(h[key],localSources,harvestingConfig)
      elsif h[key].is_a? Array
        h[key] = h[key].map{ |el|
          if el.is_a? Hash
            replaceSourcesInHash(el,localSources,harvestingConfig)
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