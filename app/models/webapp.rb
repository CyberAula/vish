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

class Webapp < ActiveRecord::Base
  before_destroy :remove_files #This callback need to be before has_attached_file, to be executed before paperclip callbacks

  include SocialStream::Models::Object

  attr_accessor :file_file_name

  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'

  define_index do
    activity_object_index
  end

  def self.createWebappFromZip(controller,zipfile)
    begin
      resource = Webapp.new
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
      #Copy attachment
      resource.file = zipfile.file

      #Unpack the ZIP file and fill the lourl, lopath, zipurl and zippath fields
      #Save the resource to get its id
      resource.save!

      if Site.current.config[:code_hostname].nil? or Site.current.config[:code_path].nil?
        webappsDirectoryPath = Rails.root.join('public', 'webappscode').to_s
      else
        webappsDirectoryPath = Site.current.config[:code_path] + "/webappscode"
      end
      loDirectoryPath = webappsDirectoryPath + "/" + resource.id.to_s
      loURLRoot = (Site.current.config[:code_hostname].nil? ? Site.current.config[:documents_hostname] : Site.current.config[:code_hostname]) + "webappscode/" + resource.id.to_s

      require "fileutils"
      FileUtils.mkdir_p(loDirectoryPath)

      Zip::ZipFile.open(zipfile.file.path) { |zip_file|
        unless zip_file.entries.map{|e| e.name}.include? "index.html"
          raise "#Invalid ZIP file for creating Web App"
        end
        zip_file.each { |f|
          f_path = File.join(loDirectoryPath, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        }
      }

      resource.zipurl = Site.current.config[:documents_hostname] + resource.file.url[1..-1]
      resource.zippath = resource.file.path
      resource.lopath = loDirectoryPath
      resource.lourl = loURLRoot + "/index.html"

      resource.save!

      #Remove previous ZIP file
      zipfile.destroy

      return resource
    rescue Exception => e
      return "Invalid Web Application (" + e.message + ")"
    end
  end

  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/webapp.png"
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
     :author => author.name,
     :src => lourl,
     :type => "webapp"
    }
  end


  private

  def remove_files
    #Remove SCORM files from the public folder
    require "fileutils"
    FileUtils.rm_rf(self.lopath)
  end
  
end
