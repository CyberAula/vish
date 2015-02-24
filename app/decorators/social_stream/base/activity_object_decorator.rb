# encoding: utf-8

ActivityObject.class_eval do
  has_many :spam_reports
  has_and_belongs_to_many :wa_resources_galleries
  has_one :contribution

  before_save :fill_relation_ids
  before_save :fill_indexed_lengths
  after_destroy :destroy_spam_reports
  after_destroy :destroy_contribution

  has_attached_file :avatar,
    :url => '/:class/avatar/:id.:content_type_extension?style=:style',
    :path => ':rails_root/documents/:class/avatar/:id_partition/:style',
    :styles => SocialStream::Documents.picture_styles

  validates_attachment_content_type :avatar, :content_type =>["image/jpeg", "image/png", "image/gif", "image/tiff", "image/x-ms-bmp"], :message => 'Avatar should be an image. Non supported format.'

  scope :with_tag, lambda { |tag|
    ActivityObject.tagged_with(tag).where("scope=0").order("ranking DESC")
  }

  scope :public_scope, lambda {
    ActivityObject.where("scope=0")
  }

  attr_accessor :score
  attr_accessor :score_tracking
  
  def public?
    !private? and self.relation_ids.include? Relation::Public.instance.id
  end

  def private?
    self.relation_ids.include? Relation::Private.instance.id
  end

  def public_scope?
    self.scope == 0
  end

  def private_scope?
    self.scope == 1
  end

  #Calculate quality score (in a 0-10 scale) 
  def calculate_qscore
    #self.reviewers_qscore is the LORI score in a 0-10 scale
    #self.users_qscore is the WBLT-S score in a 0-10 scale
    #self.teachers_qscore is the WBLT-T score in a 0-10 scale
    qscoreWeights = {}
    qscoreWeights[:reviewers] = BigDecimal(0.6,6)
    qscoreWeights[:users] = BigDecimal(0.3,6)
    qscoreWeights[:teachers] = BigDecimal(0.1,6)

    unless (self.reviewers_qscore.nil? and self.users_qscore.nil? and self.teachers_qscore.nil?)
      if self.reviewers_qscore.nil?
        reviewersScore = 0
        qscoreWeights[:reviewers] = 0
      else
        reviewersScore = self.reviewers_qscore
      end

      if self.users_qscore.nil?
        usersScore = 0
        qscoreWeights[:users] = 0
      else
        usersScore = self.users_qscore
      end

      if self.teachers_qscore.nil?
        teachersScore = 0
        qscoreWeights[:teachers] = 0
      else
        teachersScore = self.teachers_qscore
      end

      #Readjust weights to sum to 1
      weightsSum = (qscoreWeights[:reviewers]+qscoreWeights[:users]+qscoreWeights[:teachers])

      unless weightsSum===1
        qscoreWeights[:reviewers] = qscoreWeights[:reviewers]/weightsSum
        qscoreWeights[:users] = qscoreWeights[:users]/weightsSum
        qscoreWeights[:teachers] = qscoreWeights[:teachers]/weightsSum
      end

      #overallQualityScore is in a  [0,10] scale
      overallQualityScore = (qscoreWeights[:reviewers] * reviewersScore + qscoreWeights[:users] * usersScore + qscoreWeights[:teachers] * teachersScore)
    else
      #This AO has no score
      overallQualityScore = 5
    end

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
      :updated_at => self.updated_at.strftime("%d-%m-%Y"),
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

    avatarUrl = getAvatarUrl
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

    unless resource.teachers_qscore.nil?
      searchJson[:teachers_qscore] = resource.teachers_qscore.to_f
    end

    if resource.class.name == "Event"
      searchJson[:start_date] = resource.start_at.strftime("%d-%m-%Y %H:%M")
      searchJson[:end_date] = resource.end_at.strftime("%d-%m-%Y %H:%M")
      searchJson[:streaming] = resource.streaming
      unless resource.embed.nil?
        searchJson[:embed] = resource.embed.to_s
      end
    end

    if ["Video","Audio"].include? resource.class.name and resource.respond_to? "sources"
        searchJson[:sources] = resource.sources
    end

    return searchJson
  end

  def getUniversalId
    getGlobalId + "@" + Vish::Application.config.APP_CONFIG["domain"]
  end

  def getGlobalId
    self.object.class.name + ":" + self.object.id.to_s
  end

  def getType
    self.object.class.name
  end

  def getUrl
    begin
      if self.object.nil?
        return nil
      end

      if self.object_type == "Document" and !self.object.type.nil?
        helper_name = self.object.type.downcase
      elsif self.object_type == "Actor" 
        if self.object.subject_type.nil? or ["Site","RemoteSubject"].include? self.object.subject_type
          return nil
        end
        helper_name = self.object.subject_type.downcase
      else
        helper_name = self.object_type.downcase
      end

      relativePath = Rails.application.routes.url_helpers.send(helper_name + "_path",self.object)
      absolutePath = Vish::Application.config.full_domain + relativePath
      
    rescue
      nil
    end
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

    if [resource.class.name,resource.class.superclass.name].include? "Document"
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

  def getAvatarUrl
    resource = self.object
    if resource.class.name=="User"
      relativePath = resource.logo.url(:medium)
    elsif resource.class.name=="Excursion"
      absolutePath = resource.thumbnail_url
    elsif resource.class.name=="Picture"
      relativePath = document.file.url + "?style=500"
    elsif resource.avatar.exists?
      relativePath = resource.avatar.url("500",{:timestamp => false})
    elsif resource.class.name=="Video" and !resource.poster_url.nil?
      absolutePath = resource.poster_url(true)
    end

    if absolutePath.nil? and !relativePath.nil?
      absolutePath = Vish::Application.config.full_domain + relativePath
    end

    return absolutePath
  end

  def readable_language
    readable_from_list('lang.languages',self.language)
  end

  def readable_context(context)
    readable_from_list('activity_object.context_choices',context)
  end

  def readable_difficulty(difficulty)
    readable_from_list('activity_object.difficulty_choices',difficulty)
  end

  def readable_subject(subject)
    readable_from_list('activity_object.subjects_choices',subject)
  end

  def readable_from_list(list,word)
    return nil if list.nil? or word.nil?
    wordKey = word.to_s.gsub(" ","_").downcase
    default = I18n.t(list + '.other', :default => word)
    I18n.t(list + '.' + wordKey, :default =>default)
  end

  def metadata
    metadata = {}

    unless self.title.nil?
      metadata[I18n.t("activity_object.title")] = self.title
    end

    unless self.description.nil?
      metadata[I18n.t("activity_object.description")] = self.description
    end

    if !self.tag_list.nil? and self.tag_list.is_a? Array
      metadata[I18n.t("activity_object.keywords")] = self.tag_list.join(", ")
    end

    unless self.readable_language.nil?
      metadata[I18n.t("activity_object.language")] = self.readable_language
    end

    unless self.age_min.blank? or self.age_max.blank?
      metadata[I18n.t("activity_object.age_range")] = self.age_min.to_s + " - " + self.age_max.to_s
    end

    if self.object_type == "Excursion"
      #Excursions have some extra metadata fields in the json
      parsed_json = JSON(self.object.json)

      if parsed_json["context"] and parsed_json["context"]!="Unspecified"
        metadata[I18n.t("activity_object.context")] = self.readable_context(parsed_json["context"])
      end

      if parsed_json["difficulty"]
        metadata[I18n.t("activity_object.difficulty")] = self.readable_difficulty(parsed_json["difficulty"])
      end

      if parsed_json["TLT"]
        metadata[I18n.t("activity_object.tlt")] = parsed_json["TLT"].sub("PT","") #remove the PT at the beginning
      end

      if parsed_json["subject"] and parsed_json["subject"].class.name=="Array"
        parsed_json["subject"].delete("Unspecified")
        unless parsed_json["subject"].blank?
          subjects = parsed_json["subject"].map{|subject| self.readable_subject(subject) }
          metadata[I18n.t("activity_object.subjects")] = subjects.join(",")
        end
      end

      if parsed_json["educational_objectives"]
        metadata[I18n.t("activity_object.educational_objectives")] = parsed_json["educational_objectives"]
      end
    end

    return metadata
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
      options[:models] = VishConfig.getAvailableResourceModels
    end
    options[:models] = options[:models].map{|m| m.to_s }

    ids_to_avoid = getIdsToAvoid(options[:ids_to_avoid],options[:actor])
    aos = ActivityObject.where("object_type in (?) and id not in (?) and scope=0", options[:models], ids_to_avoid).order("ranking DESC").first(nSubset)

    if random
      aos = aos.sample(n)
    end

    return aos.map{|ao| ao.object}
  end

  def self.getRecent(n = 20, options={})
    nsize = [60,3*n].max
    nHalf = (n/2.to_f).ceil

    if options[:models].nil?
      options[:models] = VishConfig.getAvailableResourceModels
    end
    options[:models] = options[:models].map{|m| m.to_s }

    ids_to_avoid = getIdsToAvoid(options[:ids_to_avoid],options[:subject])
    allAOs = ActivityObject.where("object_type in (?) and id not in (?) and scope=0", options[:models], ids_to_avoid)

    aosRecent = allAOs.order("updated_at DESC").first(nsize)
    aosRecent.sort!{|b,a| a.ranking <=> b.ranking}
    aosRecent = aosRecent.first(nsize/2).sample(nHalf)

    ids_to_avoid = aosRecent.map{|ao| ao.id}
    aosPopular = allAOs.where("id not in (?)", ids_to_avoid).order("ranking DESC").first(nsize)
    aosPopular.sort!{|b,a| a.updated_at <=> b.updated_at}
    aosPopular = aosPopular.first(nsize/2).sample(nHalf)
    (aosRecent + aosPopular).map{|ao| ao.object}
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

  def self.getObjectFromUniversalId(id)
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

  def self.getObjectFromGlobalId(id)
    return nil if id.nil?
    universalId = id.to_s + "@" + Vish::Application.config.APP_CONFIG["domain"]
    getObjectFromUniversalId(universalId)
  end

  def self.getObjectFromUrl(url)
    return nil if url.blank?

    urlregexp = /([ ]|^)(http[s]?:\/\/([^\/]+)\/([a-zA-Z0-9]+)\/([0-9]+))([? ]|$)/
    regexpResult = (url =~ urlregexp)

    return nil if regexpResult.nil? or $3.nil? or ($3 != Vish::Application.config.APP_CONFIG["domain"]) or $4.nil? or $5.nil?

    begin
      modelName = $4.singularize.capitalize
      instanceId = $5
      resource = getObjectFromGlobalId(modelName + ":" + instanceId)
    rescue
      resource = nil
    end

    return resource
  end

  def self.getResourceCount
    getCount(["Workshop","Excursion", "Document", "Webapp", "Scormfile","Link","Embed"])
  end

  def self.getCount(models=[])
    ActivityObject.where("object_type in (?)", models).count
  end


  private

  def fill_relation_ids
    unless self.object.nil?
      if self.object_type != "Actor"
        #Resources
        unless ["Excursion","Workshop"].include? self.object_type and self.object.draft==true
          #Always public except drafts
          self.object.relation_ids = [Relation::Public.instance.id]
          self.relation_ids = [Relation::Public.instance.id]
        else
          self.object.relation_ids = [Relation::Private.instance.id]
          self.relation_ids = [Relation::Private.instance.id]
        end
      elsif self.object_type == "Actor"
        #Actors
        if self.object.admin?
          self.relation_ids = [Relation::Private.instance.id]
        else
          self.relation_ids = [Relation::Public.instance.id]
        end
      end
    end
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

  def after_update_qscore
    if Vish::Application.config.APP_CONFIG["qualityThreshold"] and Vish::Application.config.APP_CONFIG["qualityThreshold"]["create_report"] and !self.qscore.nil?
      overallQualityScore = (self.qscore/100000.to_f)
      if overallQualityScore < Vish::Application.config.APP_CONFIG["qualityThreshold"]["create_report"].to_f
        #Generate spamReport (prevent duplicates)
        if self.lowQualityReports.blank?
          report = SpamReport.new(:activity_object_id=> self.id, :reporter_actor_id => Site.current.actor.id, :issue=> I18n.t("report.low_content_quality_msg", :locale => I18n.default_locale), :report_value=> 2)
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

  def destroy_contribution
    unless self.contribution.nil?
      self.contribution.destroy
    end
  end

end
