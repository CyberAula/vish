# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

class SpamReport < ActiveRecord::Base
  belongs_to :activity_object

  validates :report_value,
  :presence => true
  validates_inclusion_of :report_value, :in => [0, 1], :allow_nil => false, :message => I18n.t('spam.report_error')
  #Report value: 0=spam/inappropriate content, 1=error

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
     	errors.add(:report, I18n.t('spam.report_error'))
     end
  end

  def actor_reporter
  	Actor.find_by_id(self.reporter_actor_id)
  end

  def actor
    self.activity_object.owner
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
      "Spam or inappropriate content"
    when 1
      "Error in the resource"
    else
      "Unknown"
    end
  end

  def issueIcon
    case self.report_value
    when 0
      #Spam or inappropriate content
     ('<i class="icon-flag"></i>').html_safe
    when 1
      #Error in the resource
      ('<i class=" icon-warning-sign"></i>').html_safe
    else
      ''
    end
  end

  def self.disabledActivityObjectTypes
    ["Actor","Post"]
  end

end

