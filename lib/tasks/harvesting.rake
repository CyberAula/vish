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

        afterRetrieveLO(lojson,url,searchURL,harvestingConfig){ |lo|
          yield lo,true if block_given?
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
          yield "LO could not be created",nil if block_given?
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

    if json["type"]==="presentation"
      lo = createVEPresentation(json,searchjson,owner,url,harvestingConfig)
    end

    #Quality metrics
    lo.calculate_qscore
    
    return lo
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
    
    #Resources
    resourceURLmapping = {}
    domain = URI.parse(url).host
    ["image","object","video","audio"].each do |rType|
      resources = VishEditorUtils.getResources(json, [rType]).select{|r| URI.parse(r).kind_of?(URI::HTTP)}.uniq
      resources.select{|r| URI.parse(r).host === domain}.each do |r|
        #Resource stored in the foreign ViSH instance
        case rType
        when "image"
          #Create picture
          imageURL = createPicture(r,owner)
          resourceURLmapping[r] = imageURL unless imageURL.blank?
        when "object"
        when "video"
        when "audio"
        else
        end
      end
    end
    
    resourceURLmapping.each do |oldURL,newURL|
      json = replaceStringInHash(json,oldURL,newURL)
    end

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
      pictureURL = URI.encode(pictureURL)
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