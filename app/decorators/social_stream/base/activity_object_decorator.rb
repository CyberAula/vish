ActivityObject.class_eval do

  has_many :spam_reports

  before_save :fill_indexed_lengths
  before_destroy :destroy_spam_reports


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

    after_update_qscore

    overallQualityScore
  end

  def lowQualityReports
    self.spam_reports.where(:report_value=>2)
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
      searchJson[:slide_count] = resource.slide_count
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
      if ["Picture","Swf"].include? resource.class.name
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

  def self.getPopular(n=20,options={})
    random = (options[:random]!=false)
    if random
      nSubset = [80,4*n].max
    else
      nSubset = n
    end

    if options[:models].nil?
      options[:models] = ["Excursion", "Document", "Webapp", "Scormfile","Link","Embed"]
    end

    ids_to_avoid = getIdsToAvoid(options[:ids_to_avoid],options[:actor])
    aos = ActivityObject.joins(:activity_object_audiences).where("activity_objects.object_type in (?) and activity_objects.id not in (?) and activity_object_audiences.relation_id in (?)", options[:models], ids_to_avoid, Relation::Public.first.id).order("ranking DESC").first(nSubset)

    if random
      aos = aos.sample(n)
    end

    return aos.map{|ao| ao.object}
  end

   def self.getIdsToAvoid(ids_to_avoid=[],actor=nil)
    ids_to_avoid = ids_to_avoid || []

    if !actor.nil?
      ids_to_avoid.concat(ActivityObject.authored_by(actor).map{|ao| ao.id})
      ids_to_avoid.uniq!
    end

    if !ids_to_avoid.is_a? Array or ids_to_avoid.empty?
      #if ids=[] the queries may returns [], so we fill it with an invalid id (no excursion will ever have id=-1)
      ids_to_avoid = [-1]
    end

    return ids_to_avoid
  end

  def self.getActivityObjectFromUniversalId(id)
    #Universal id example: "Excursion:616@localhost:3000"
    begin
      fSplit = id.split("@")
      unless fSplit[1]==Vish::Application.config.APP_CONFIG["domain"]
        raise "This resource does not belong to this domain"
      end
      sSplit = fSplit[0].split(":")
      objectType = sSplit[0]
      objectId = sSplit[1]
      objectType.singularize.classify.constantize.find_by_id(objectId)
    rescue
      nil
    end
  end


  private

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

  def after_update_qscore
    if Vish::Application.config.APP_CONFIG["qualityThreshold"] and Vish::Application.config.APP_CONFIG["qualityThreshold"]["create_report"] and !self.qscore.nil?
      overallQualityScore = (self.qscore/100000.to_f)
      if overallQualityScore < Vish::Application.config.APP_CONFIG["qualityThreshold"]["create_report"].to_f
        #Generate spamReport (prevent duplicates)
        if self.lowQualityReports.blank?
          report = SpamReport.new(:activity_object_id=> self.id, :reporter_actor_id => Site.current.actor.id, :issue=> I18n.t("report.low_content_quality_msg"), :report_value=> 2)
          report.save!
        end
      end
    end
  end

  def destroy_spam_reports
    SpamReport.where(:activity_object_id => self.id).each do |spamReport|
      spamReport.destroy
    end
  end

end