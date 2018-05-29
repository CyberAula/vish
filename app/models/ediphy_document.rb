class EdiphyDocument < ActiveRecord::Base
  # attr_accessible :title, :body
  include SocialStream::Models::Object
  belongs_to :owner, class_name: "Actor"
  define_index do
    activity_object_index
    has draft
  end
  after_save :parse_for_meta
  after_save :fix_post_activity_nil

  has_many :ediphy_exercises

  def absolutePath
    Vish::Application.config.full_domain + relativePath
  end

  def relativePath
    "/ediphy_documents/" + self.id.to_s + "/edit"
  end

  def thumbnail
    JSON.parse(self.json)["present"]["globalConfig"]["thumbnail"] || ""
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

    #Try to infer the language of the excursion if it is not spcifiyed
    if (self.language.nil? or !self.language.is_a? String or self.language=="independent")
      self.inferLanguage
    end

    if self.notified_teacher == true
      self.notified_teacher = false
      self.save
    end

    #If LOEP is enabled, upload the excursion to LOEP
    unless Vish::Application.config.APP_CONFIG['loep'].nil?
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
            eJson = JSON(self.json)
            eJson["language"] = lan
            self.update_column :json, eJson.to_json
            break
          end
        end
      end
    end
  end

  private

   def parse_for_meta
      if self.draft
        activity_object.scope = 1
      else
        activity_object.scope = 0
      end
      activity_object.save!
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
