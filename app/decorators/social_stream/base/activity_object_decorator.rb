ActivityObject.class_eval do

  before_save :fill_indexed_lengths

  #Calculate quality score (in a 0-10 scale) 
  def calculate_qscore
    #self.reviewers_qscore is the LORI score in a 0-10 scale
    #self.users_qscore is the WBLT-S score in a 0-10 scale
    qscoreWeights = {}
    qscoreWeights[:reviewers] = BigDecimal(0.9,6)
    qscoreWeights[:users] = BigDecimal(0.1,6)

    if self.reviewers_qscore.nil?
      #If nil, we consider it 5 in a [0,10] scale.
      reviewerScore = BigDecimal(5.0,6)
    else
      reviewerScore = self.reviewers_qscore
    end

    if self.users_qscore.nil?
      #If nil, we consider it 5 in a [0,10] scale.
      usersScore = BigDecimal(5.0,6)
    else
      usersScore = self.users_qscore
    end

    #overallQualityScore is in a  [0,10] scale
    overallQualityScore = (qscoreWeights[:users] * usersScore + qscoreWeights[:reviewers] * reviewerScore)

    #Translate it to a scale of [0,1000000]
    overallQualityScore = overallQualityScore * 100000

    self.update_column :qscore, overallQualityScore
  end

  def fill_indexed_lengths
    if self.title.is_a? String and self.title.scan(/\w+/).size>0
      self.title_length = self.title.scan(/\w+/).size
    end
    if self.description.is_a? String and self.description.scan(/\w+/).size>0
      self.desc_length = self.description.scan(/\w+/).size
    end
    if self.tag_list.is_a? ActsAsTaggableOn::TagList and self.tag_list.length>0
      self.tags_length = self.tag_list.length
    end
  end

  ##############
  # Return JSON to the SEARCH API (federated search)
  ##############
  def search_json(controller)
    resource = self.object

    #Title
    unless resource.class.name == "User"
      title = resource.title
    else
      title = resource.name
    end

    #Author
    begin
      authorName = resource.author.name
      author_profile_url = controller.url_for(resource.author.user)
    rescue
      authorName = nil
      author_profile_url = nil
    end

    #Common fields
    searchJson =  {
      :id => self.getUniversalId(),
      :type => self.getType(),
      :created_at => self.created_at.strftime("%d-%m-%Y"),
      :title => title,
      :description => resource.description || "",
      :tags => resource.tag_list,
      :url =>  controller.url_for(resource)
    }

    fullUrl = self.getFullUrl(controller)
    unless fullUrl.nil?
      searchJson[:url_full] = fullUrl
    end

    downloadUrl = self.getDownloadUrl(controller)
    unless downloadUrl.nil?
      searchJson[:file_url] = downloadUrl
    end

    unless authorName.nil? or author_profile_url.nil?
      searchJson[:author] = authorName
      searchJson[:author_profile_url] = author_profile_url
    end

    unless resource.language.blank?
      searchJson[:language] = resource.language
    end

    avatarUrl = getAvatardUrl(controller)
    unless avatarUrl.nil?
      searchJson[:avatar_url] = avatarUrl
    end

    unless resource.class.name == "User"
      searchJson[:visit_count] = self.visit_count
      searchJson[:like_count] = self.like_count
      searchJson[:download_count] = self.download_count
    else
      unless resource.occupation.nil?
        searchJson[:occupation] = resource.occupation_t
      end
    end

    if resource.class.name == "Excursion"
      searchJson[:loModel] = JSON(resource.json)
    end

    unless resource.reviewers_qscore.nil?
      searchJson[:reviewers_qscore] = resource.reviewers_qscore.to_f
    end

    unless resource.users_qscore.nil?
      searchJson[:users_qscore] = resource.users_qscore.to_f
    end

    if resource.class.name == "Event"
      searchJson[:start_date] = resource.start_at.strftime("%d-%m-%Y %H:%M")
      searchJson[:end_date] = resource.end_at.strftime("%d-%m-%Y %H:%M")
      searchJson[:streaming] = resource.streaming
      unless resource.embed.nil?
        searchJson[:embed] = resource.embed.to_s
      end
    end

    if ["Video","Audio"].include? resource.class.name
      if resource.class.name == "Video"
        searchJson[:sources] = [
          { type: Mime::WEBM.to_s, src: controller.video_url(resource, :format => :webm) },
          { type: Mime::MP4.to_s,  src: controller.video_url(resource, :format => :mp4) },
          { type: Mime::FLV.to_s,  src: controller.video_url(resource, :format => :flv) }
        ]
      elsif resource.class.name == "Audio"
        searchJson[:sources] = [
          { type: Mime::MP3.to_s, src: controller.audio_url(resource, :format => :mp3) },
          { type: Mime::WAV.to_s,  src: controller.audio_url(resource, :format => :wav) },
          { type: Mime::WEBMA.to_s,  src: controller.audio_url(resource, :format => :webma) }
        ]
      end
    end

    return searchJson
  end

  def getUniversalId
    self.object.class.name + ":" + self.object.id.to_s + "@" + Vish::Application.config.APP_CONFIG["domain"]
  end

  def getType
    self.object.class.name
  end

  def getFullUrl(controller)
    relativePath = nil
    absolutePath = nil

    resource = self.object

    if resource.class.superclass.name=="Document"
      if ["Picture"].include? resource.class.name
        relativePath = resource.file.url
      end
    elsif ["Scormfile","Webapp"].include? resource.class.name
      absolutePath = resource.lourl
    elsif ["Excursion"].include? resource.class.name
      # relativePath = Rails.application.routes.url_helpers.excursion_path(resource, :format=> "full")
      absolutePath = controller.url_for(resource) + ".full"
    elsif ["Link"].include? resource.class.name
      absolutePath = resource.url
    elsif ["Embed"].include? resource.class.name
      # absolutePath = resource.fulltext
      # Not secure. Extract url from fulltext may work.
    end

    if absolutePath.nil? and !relativePath.nil?
      absolutePath = Vish::Application.config.full_domain + relativePath
    end

    return absolutePath
  end

  def getDownloadUrl(controller)
    relativePath = nil
    absolutePath = nil

    resource = self.object

    if resource.class.superclass.name=="Document"
      relativePath = resource.file.url
    elsif ["Scormfile","Webapp"].include? resource.class.name
      absolutePath = resource.zipurl
    elsif ["Excursion"].include? resource.class.name
      # relativePath = Rails.application.routes.url_helpers.excursion_path(resource, :format=> "scorm")
      absolutePath = controller.url_for(resource) + ".scorm"
    end

    if absolutePath.nil? and !relativePath.nil?
      absolutePath = Vish::Application.config.full_domain + relativePath
    end

    return absolutePath
  end

  def getAvatardUrl(controller)
    resource = self.object

    if resource.class.name=="User"
      relativePath = resource.logo.to_s
    elsif resource.class.name=="Excursion"
      absolutePath = resource.thumbnail_url
    end

    if absolutePath.nil? and !relativePath.nil?
      absolutePath = Vish::Application.config.full_domain + relativePath
    end

    return absolutePath
  end


  ##############
  ## Class Methods
  ##############

  def self.getPopular(n=20,models=nil,preSelection=nil,user=nil)
    resources = []
    nSubset = [80,4*n].max

    if models.nil?
      #All models
      models = ["Excursion", "Document", "Webapp", "Scormfile","Link","Embed"]
    end

    ids_to_avoid = getIdsToAvoid(preSelection,user)

    ActivityObject.where("object_type in (?) and id not in (?)", models, ids_to_avoid).order("ranking DESC").limit(nSubset).sample(n).map{|ao| ao.object}
  end

  def self.getIdsToAvoid(preSelection=nil,user=nil)
    ids_to_avoid = []

    if preSelection.is_a? Array
      ids_to_avoid = preSelection.map{|e| e.id}
    end

    if !user.nil?
      ids_to_avoid.concat(ActivityObject.authored_by(user).map{|ao| ao.id})
    end

    ids_to_avoid.uniq!

    if !ids_to_avoid.is_a? Array or ids_to_avoid.empty?
      #if ids=[] the queries may returns [], so we fill it with an invalid id (no excursion will ever have id=-1)
      ids_to_avoid = [-1]
    end

    return ids_to_avoid
  end

end