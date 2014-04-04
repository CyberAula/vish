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

class Zipfile < Document
  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'
  
  define_index do
    activity_object_index
    indexes file_file_name, :as => :file_name
  end
    
  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/zip.png"
  end

  def as_json(options)
    super.merge!({
      :src => options[:helper].polymorphic_url(self, format: format)
    })
  end

  def fileType
    if self.file.class != Paperclip::Attachment or self.file.path.blank?
      return Zipfile
    end

    isScorm = false
    Zip::ZipFile.open(self.file.path) do |zip|
      isScorm = zip.entries.map{|e| e.name}.include? "imsmanifest.xml"
    end
    
    if isScorm
      return Scormfile
    end

    return Zipfile
  end

  def getResourceAfterSave
    case self.fileType.name
    when Scormfile.name
      resource = Scormfile.createScormfileFromZip(self)
    else
      resource = self
    end
    return resource
  end
  
end