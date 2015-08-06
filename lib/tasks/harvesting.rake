# encoding: utf-8

namespace :harvesting do

  #Usage
  #Development:   bundle exec rake harvesting:harvestILSs
  #In production: bundle exec rake harvesting:harvestILSs RAILS_ENV=production
  task :harvestILSs => :environment do
    printTitle("Harvest ILSs")

    owner = Actor.find_by_email("virtual.science.hub+1@gmail.com")
    ils_api_url = "http://www.golabz.eu/rest/ils/retrieve.json"

    #Generate Category to store all objects
    c = Category.authored_by(owner).readonly(false).select{|c| c.title=="Inquiry Learning Spaces - GoLab"}.first
    c = Category.new if c.nil?
    c.owner_id = owner.id
    c.author_id = owner.id
    c.user_author_id = owner.id
    c.scope = 0
    c.title = "Inquiry Learning Spaces - GoLab"
    c.description = "Inquiry Learning Spaces are online labs embedded in resources and scaffolds to offer students a complete inquiry learning experience. See more at: http://www.go-lab-project.eu/inquiry-learning-spaces ."
    c.save

    begin
      require 'open-uri'
      content = open(ils_api_url).read
      parsed_content = JSON.parse(content)
    rescue Exception => e
      puts "Exceptiion"
      puts e.message
      exit 1
    end

    parsed_content.each do |ils|

      next if ils["student_link"].blank?
      next if ils["author"].blank?
      next if ils["ils_license"].blank?
      next if ils["title"].blank?


      #################
      # Generate Link
      #################

      l = nil

      lLink = ils["student_link"].split("http://graasp.eu")[1].split("?")[0] rescue ""
      l = Link.where("links.url LIKE '%" + lLink + "%'").first
      next if !l.nil? and l.owner_id != owner.id

      l = Link.new if l.nil?
      
      l.owner_id = owner.id
      l.author_id = owner.id
      l.user_author_id = owner.id
      l.scope = 0
      l.title = ils["title"] unless ils["title"].blank?
      l.description = ils["description"] unless ils["description"].blank?
      l.url = ils["student_link"] unless ils["student_link"].blank?
      l.original_author = ils["author"] unless ils["author"].blank?
      l.tag_list = ils["ils_keywords"] unless ils["ils_keywords"].blank? or !ils["ils_keywords"].is_a? Array or !l.tag_list.blank?
      if ils["ils_language"] and ils["ils_language"].is_a? Array
        language = ils["ils_language"].map{|ilsl| processILSLanguage(ilsl) }.first
        l.language = language unless language.blank?
      end
      if ils["ils_age_range"] and ils["ils_age_range"].is_a? Array
        ageRanges = processILSAgeRanges(ils["ils_age_range"])
        unless ageRanges.nil?
          l.age_min = ageRanges[0]
          l.age_max = ageRanges[1]
        end
      end
      unless ils["ils_license"].blank? or l.original_author.blank? or l.url.blank?
        licenseKey = processILSLicense(ils["ils_license"])
        licenseRecord = License.find_by_key(licenseKey)
        next if licenseRecord.nil?
        l.license_id = licenseRecord.id
        l.license_attribution = l.original_author + " (" + l.url + ")"
      end

      avatarURL = ils["ils_thumb"] || ils["ils_image"]
      unless avatarURL.blank? or l.avatar.exists?
        downloadAndUploadAvatarForAo(avatarURL,l)
      end

      l.save
      
      c.property_objects << l.activity_object unless l.activity_object.nil?


      #################
      # Generate Excursion
      #################

      e = nil
      
      #Find excursion using link
      e = Excursion.all.select{|e| (JSON(e.json)["slides"][0]["elements"][0]["body"].include? ils["student_link"]) rescue false}.first
      next if !e.nil? and e.owner_id != owner.id

      e = Excursion.new if e.nil?
      
      e.owner_id = owner.id
      e.author_id = owner.id
      e.user_author_id = owner.id
      e.original_author = ils["author"] unless ils["author"].blank?
      e.license_id = licenseRecord.id
      e.license_attribution = e.original_author + " (" + ils["student_link"] + ")"

      #Generate JSON
      eJson = {
        VEVersion: "0.9.1",
        type: "presentation",
        title: ils["title"],
        author: {
          name: owner.name,
          vishMetadata: {
            id: owner.id
          }
        },
        license: {
          name: licenseRecord.name,
          key: licenseRecord.key
        },
        theme: "theme1",
        animation: "animation1",
        slides: [
          {
            id: "article2",
            type: "standard",
            template: "t10",
            elements: [
              {
                id: "article2_zone1",
                type: "object",
                areaid: "center",
                settings: {
                  unloadObject: false
                },
                body: '<iframe src="' + ils["student_link"] + '?wmode=opaque" wmode="opaque" id="resizableunicID1" class="t10_object"></iframe>',
                style: "position: relative; width:100%; height:100%; top:0%; left:0%;",
                subtype: "web"
              }
            ]
          }
        ]
      }

      eJson["description"] = ils["description"] unless ils["description"].blank?
      if e.thumbnail_url.nil?
        unless avatarURL.blank?
          newAvatarURL = downloadAndUploadAvatar(avatarURL,owner)
          eJson["avatar"] = newAvatarURL unless newAvatarURL.blank?
        end
      else
        eJson["avatar"] = e.thumbnail_url
      end

      if e.tag_list.blank?
        eJson["tags"] = ils["ils_keywords"] unless ils["ils_keywords"].nil? or !ils["ils_keywords"].is_a? Array
      else
        eJson["tags"] = e.tag_list
      end
      eJson["language"] = language unless language.nil?
      unless ageRanges.nil?
        eJson["age_range"] = ageRanges[0].to_s + " - " + ageRanges[1].to_s
      end

      difficulty = processILSDifficulty(ils["ils_difficulty_level"])
      tlt = processILSTLT(ils["ils_didactical_time"])
      eJson["difficulty"] = difficulty unless difficulty.blank?
      eJson["TLT"] = tlt unless tlt.blank?

      e.json = eJson.to_json

      e.save
      e.afterPublish

      c.property_objects << e.activity_object unless e.activity_object.nil?

      #Check category
      c.setPropertyObjects #make property objects uniq
    end
    
    printTitle("Task Finished")
  end

  def processILSLanguage(ilsLanguage)
    case ilsLanguage
    when "English"
      return "en"
    when "Spanish"
      return "es"
    when "Portuguese"
      return "pt"
    when "Dutch"
      return "nl"
    when "French"
      return "fr"
    when "Italian"
      return "it"
    when "Hungarian"
      return "hu"
    else
      return "ot"
    end
  end

  def processILSAgeRanges(ilsAgeRanges)
    min = ilsAgeRanges.first.split("-")[0].to_i rescue nil
    max = ilsAgeRanges.last.split("-")[1].to_i rescue nil
    return nil if min.nil? or max.nil?
    [min,max]
  end

  def processILSLicense(ilsLicense)
    case ilsLicense
    when "Creative Commons Attribution (CC BY)"
      return "cc-by"
    when "Creative Commons Attribution-NonCommercial (CC BY-NC)"
      return "cc-by-nc"
    when "Creative Commons Attribution-ShareAlike (CC BY-SA)"
      return "cc-by-sa"
    when "Creative Commons Attribution-NoDerivs (CC BY-ND)"
      return "cc-by-nd"
    when "Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)"
      return "cc-by-nc-sa"
    when "Creative Commons Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)"
      return "cc-by-nc-nd"
    else
      return nil
    end
  end

  def processILSDifficulty(difficulty)
    case difficulty
    when "Advanced"
      return "difficult"
    when "Medium"
      return "medium"
    when "Easy"
      return "easy"
    else
      return nil
    end
  end

  def processILSTLT(tlt)
    case tlt
    when "More than 3 didactic hours"
      return "PT4H0M0S"
    when "3 didactic hours"
      return "PT3H0M0S"
    when "2 didactic hours"
      return "PT2H0M0S"
    when "1 didactic hour"
      return "PT1H0M0S"
    when "Less than 1 didactic hour"
      return "PT0H30M0S"
    else
      return nil
    end
  end

  def downloadAndUploadAvatarForAo(pictureURL,ao)
    begin
      id = Picture.count + 1
      pictureURI = URI.parse(pictureURL)
      fileName = id.to_s + "_" + File.basename(pictureURI.path)
      filePath = "tmp/externalAvatars/" + fileName
      # pictureURL = URI.encode(pictureURL)
      command = "wget " + pictureURL + " --output-document='" + filePath + "'"
      system(command)
    rescue => e
      return nil
    end
    
    unless filePath.nil? or !File.exist?(filePath) or File.zero?(filePath)
      ao.avatar = File.open(filePath, "r") rescue nil
    end

    return ao
  end

  def downloadAndUploadAvatar(pictureURL,owner)
    begin
      index = Picture.count + 1
      pictureURI = URI.parse(pictureURL)
      fileName = index.to_s + "_" + File.basename(pictureURI.path)
      filePath = "tmp/externalAvatars/" + fileName
      # pictureURL = URI.encode(pictureURL)
      command = "wget " + pictureURL + " --output-document='" + filePath + "'"
      system(command)
    rescue => e
      filePath = nil
      fileName = index.to_s + "_default"
    end
    
    if filePath.nil? or !File.exist?(filePath) or File.zero?(filePath)
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
      filePath = Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png'
      pic.file = File.open(filePath, "r")
      pic.save!
    end

    return pic.getAvatarUrl
  end

end