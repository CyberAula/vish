class SpamReport < ActiveRecord::Base
  belongs_to :activity_object

  validates :report_value,
  :presence => true
  validates_inclusion_of :report_value, :in => [0, 1, 2], :allow_nil => false, :message => I18n.t('report.failure')
  #Report value: 0=spam/inappropriate content, 1=error, 2=low quality content

  validates :activity_object_id,
  :presence => true

  validate :is_activity_object_valid

  def is_activity_object_valid
  	validAO = false
  	unless self.activity_object_id.nil?
        ao = ActivityObject.find_by_id(self.activity_object_id)
        unless ao.nil? or ao.object_type.nil? or ao.object.nil?
          unless SpamReport.disabledActivityObjectTypes.include? ao.object_type
            validAO = true
          end
        end
    end

     if validAO
     	true
     else
     	errors.add(:report, I18n.t('report.failure'))
     end
  end

  def actor_reporter
  	Actor.find_by_id(self.reporter_actor_id)
  end

  def actor
    unless self.activity_object.nil?
      self.activity_object.owner
    else
      nil
    end
  end

  def reporterName
    theReporter = self.actor_reporter
    if theReporter.nil?
      I18n.t('user.anonymous')
    else
      theReporter.subject.name
    end
  end

  def issueType
    case self.report_value
    when 0
      #"Spam or inappropriate content"
      I18n.t("report.spam_content", :locale => I18n.default_locale)
    when 1
      #"Error in the resource"
      I18n.t("report.error_content_resource", :locale => I18n.default_locale)
    when 2
      #"Low quality resource"
      I18n.t("report.low_content_quality", :locale => I18n.default_locale)
    else
      I18n.t("unknown", :locale => I18n.default_locale)
    end
  end

  def issueIcon
    case self.report_value
    when 0
      #Spam or inappropriate content
     ('<i class="fa fa-flag"></i>').html_safe
    when 1
      #Error in the resource
      ('<i class="fa fa-warning"></i>').html_safe
    when 2
      #Low quality resource
      ('<i class="fa fa-times"></i>').html_safe
    else
      ''
    end
  end

  def self.disabledActivityObjectTypes
    ["Actor","Post"]
  end

end

