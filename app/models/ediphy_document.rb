class EdiphyDocument < ActiveRecord::Base
  
  include SocialStream::Models::Object
  has_many :ediphy_document_contributors, :dependent => :destroy
  has_many :contributors, :class_name => "Actor", :through => :ediphy_document_contributors

  before_validation :fill_license
  after_save :parse_for_meta
  after_save :fix_post_activity_nil
  
  define_index do
    activity_object_index

    has draft
  end

  def thumbnail
    thumbnail = (JSON.parse(self.json)["present"]["globalConfig"]["thumbnail"] || "") rescue ""
    thumbnail = thumbnail + "?style=500" if thumbnail!="" and /data:image/.match(thumbnail).nil? and /style=500/.match(thumbnail).nil?
    thumbnail
  end

  def afterPublish
    #Check if post_activity is public. If not, make it public and update the created_at param.
    post_activity = self.post_activity
    unless post_activity.nil? or post_activity.public?
      #Update the created_at param.
      post_activity.created_at = Time.now
      #Make it public
      post_activity.relation_ids = [Relation::Public.instance.id]
      post_activity.save!
    end

    #Try to infer the language of the ediphy document if it is not spcifiyed
    if (self.language.nil? or !self.language.is_a? String)
      self.inferLanguage
    end

    #If LOEP is enabled and EdiphyDocument is evaluable, register the ediphy document in LOEP
    if VishConfig.getAvailableEvaluableModels.include?("EdiphyDocument")
      VishLoep.sendActivityObject(self.activity_object) rescue nil
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
            edJson = JSON(self.json)
            edJson["present"]["globalConfig"]["language"] = lan
            self.update_column :json, edJson.to_json
            break
          end
        end
      end
    end
  end
  def clone_for sbj
    return nil if sbj.blank?
    unless self.clonable? or sbj.admin? or (sbj===self.owner)
      return nil
    end

    contributors = self.contributors || []
    contributors.push(self.author)
    contributors.uniq!
    contributors.delete(sbj)

    e = EdiphyDocument.new
    e.author=sbj
    e.owner=sbj
    e.user_author=sbj.user.actor
    eJson = JSON(self.json)
    eJson["present"]["globalConfig"]["author"] = sbj.name
    unless contributors.blank?
      eJson["present"]["globalConfig"]["contributors"] = contributors.map{|c| {name: c.name, vishMetadata:{ id: c.id}}}
    end
    eJson.delete("license")
    eJson["present"]["status"] = "draft"
    e.json = eJson.to_json

    e.contributors=contributors
    e.draft=true

    e.save!
    e
  end
  private

  def fill_license
    if ((self.scope_was!=0 or self.new_record?) and (self.scope==0))
      if self.license.nil? or self.license.private?
        license_metadata = JSON(self.json)["present"]["globalConfig"]["rights"] rescue nil
        license = License.find_by_key(license_metadata)
        self.license_id = license.id unless license.nil?
        if self.license.nil? or self.license.private?
          self.license_id = License.default.id
        end
      end
    end
  end
   
  def parse_for_meta
    globalconfig = JSON(self.json)["present"]["globalConfig"]
    activity_object.title = (globalconfig["title"].nil? ? "Untitled" : globalconfig["title"])
    activity_object.description = globalconfig["description"]

    parsed_tag_list = []
    globalconfig["keywords"].each do |key|
      parsed_tag_list.push(key["text"].nil? ? key: key["text"])
    end
    activity_object.tag_list = parsed_tag_list

    activity_object.language = globalconfig["language"]


    unless globalconfig["allowClone"].nil?
      activity_object.allow_clone = globalconfig["allowClone"]
    end

    unless globalconfig["allowComments"].nil?
      activity_object.allow_comment = globalconfig["allowComments"]
    end

    unless globalconfig["allowDownload"].nil?
      activity_object.allow_download = globalconfig["allowDownload"]
    end


    unless globalconfig["age"].blank?
      begin
        activity_object.age_min = globalconfig["age"]["min"]
        activity_object.age_max = globalconfig["age"]["max"]
      rescue
      end
    end

    ori_updated_at = self.updated_at

    if self.draft
      activity_object.scope = 1
    else
      activity_object.scope = 0
    end
    activity_object.save!

    self.update_column :updated_at, ori_updated_at
    activity_object.update_column :updated_at, ori_updated_at
  end
   
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

end