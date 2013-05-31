class Document < ActiveRecord::Base
  include SocialStream::Models::Object

  IMAGE_FORMATS = ["doc","ppt","xls","rar","zip","mpeg","plain","pdf"]

  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:style/:filename.:extension'

  paginates_per 20
  
  validates_attachment_presence :file
  validates_presence_of :title
  
  before_validation(:on => :create) do
    set_title
  end
  
  define_index do
    activity_object_index

    indexes file_file_name, :as => :file_name
    indexes type, :as => :document_type
  end
  
  class << self 
    def new(*args)

      if !(self.name == "Document")
        return super
       end 
      doc = super
      
      if(doc.file_content_type.nil?)
        return doc
      end

      if !(doc.file_content_type =~ /^application.*vnd.oasis.*/).nil? or
         !(doc.file_content_type =~ /^application.*vnd.openxmlformats-officedocument.*/).nil? or
         !(doc.file_content_type =~ /^application.*pdf/).nil? or
         !(doc.file_content_type =~ /^application.*ms.?excel/).nil? or
         !(doc.file_content_type =~ /^application.*ms.?word/).nil? or
         !(doc.file_content_type =~ /^application.*ms.?powerpoint/).nil?
        return Officedoc.new *args
      end

      if !(doc.file_content_type =~ /^.*shockwave-flash.*/).nil?
        return Swf.new *args
      end
      
      if !(doc.file_content_type =~ /^image.*/).nil?
        return Picture.new *args
      end
      
      if !(doc.file_content_type =~ /^audio.*/).nil?
        return Audio.new *args
      end
      
      if !(doc.file_content_type =~ /^video.*/).nil?
        return Video.new *args
      end
      
      return doc
    end
  end

  def mime_type
    Mime::Type.lookup(file_content_type)
  end

  def format
    mime_type.to_sym
  end

  # Thumbnail file
  def thumb(size, helper)
    if format && IMAGE_FORMATS.include?(format.to_s)
      "#{ size.to_s }/#{ format }.png"
    else
      "#{ size.to_s }/default.png"
    end
  end

 # JSON, generic version for most documents
  def as_json(options = nil)
    {:id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :src => documents_hostname + file.to_s.downcase
    }
  end
  
  protected

  def set_title
    self.title = file_file_name if self.title.blank?
  end

  def documents_hostname
    Site.current.config[:documents_hostname].to_s
  end
end

ActiveSupport.run_load_hooks(:document, Document) 
