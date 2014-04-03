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

class Scormfile < ActiveRecord::Base
  include SocialStream::Models::Object

  define_index do
    activity_object_index
  end

  def self.createScormfileFromZip(zipfile)
    begin
      #Check if its a valid SCORM package
      Scorm::Package.open(zipfile.file) do |pkg|
      end
      
      resource = Scormfile.new
      resource.owner_id = zipfile.owner_id
      resource.author_id = zipfile.author_id
      resource.user_author = zipfile.user_author
      resource.activity_object.relation_ids = zipfile.activity_object.relation_ids
      resource.activity_object.title = zipfile.activity_object.title
      resource.activity_object.description = zipfile.activity_object.description
      resource.activity_object.age_min = zipfile.activity_object.age_min
      resource.activity_object.age_max = zipfile.activity_object.age_max
      resource.activity_object.language = zipfile.activity_object.language
      resource.activity_object.tag_list = zipfile.activity_object.tag_list
      resource.save!

      #TODO, create attachment!

      return resource
    rescue Exception => e
      return "Invalid SCORM package (" + e.message + ")"
    end
  end

  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/scorm.png"
  end


  #Overriding mimetype and format methods from SSDocuments

  # The Mime::Type of this document's file
  def mime_type
    Mime::Type.new("application/zip")
  end

  # The type part of the {#mime_type}
  def mime_type_type_sym
    mime_type.to_s.split('/').last.to_sym
  end

  # {#mime_type}'s symbol
  def format
    mime_type.to_sym
  end


  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name
    }
  end
  
end
