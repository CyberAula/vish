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
      return resource
    rescue Exception => e
      return "Invalid SCORM package (" + e.message + ")"
    end
  end

  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/scorm.png"
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
