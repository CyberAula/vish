class Video < Document  
  has_attached_file :file, 
                    :url => '/:class/:id.:content_type_extension',
                    :default_url => 'missing_:style.png',
                    :path => ':rails_root/documents/:class/:id_partition/:style',
                    :styles => SocialStream::Documents.video_styles,
                    :processors => SocialStream::Documents.video_processors
                    
  if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
    process_in_background :file
  end
  
  define_index do
    activity_object_index

    indexes file_file_name, :as => :file_name
  end


  def source_for_format(format_symbol)
    unless format_symbol.is_a? Symbol
      format_symbol = format_symbol.to_sym
    end
    #mimetype = "Mime::#{format_symbol.to_s.upcase}".constantize.to_s rescue format_symbol.to_s
    mimetype = Mime::Type.lookup_by_extension(format_symbol).to_s
    {format: format_symbol, type: mimetype, src: Vish::Application.config.full_domain + Rails.application.routes.url_helpers.video_path(self, :format => format_symbol)}
  end

  #Original source
  def source
    self.source_for_format(self.format)
  end

  #Original source url
  def source_url
    self.source[:src]
  end

  #Converted sources (or original source if media conversion is not enabled)
  def sources
    sources = []
    #Entry example: {:type=>"video/x-msvideo", :src=>"/videos/main.avi"}
    
    if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
      video_formats = SocialStream::Documents.video_styles.map{|k,v| k}.reject{|k| k==:"170x127#"}
      video_formats.each do |format_symbol|
        sources.push(self.source_for_format(format_symbol))
      end
    else
      sources.push(self.source)
    end

    sources
  end

  #Include converted sources and the original
  def all_sources
    (sources+[source]).uniq
  end

  def poster_url(includeDefault=false)
    if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
      #Check if the file actually exists
      # attachment_path = self.file.path.gsub("original","")
      # output = (system "ls #{attachment_path} | grep 170x127#")
      # if output===true
      # end
      return Vish::Application.config.full_domain + Rails.application.routes.url_helpers.video_path(self, :format => :png, :style => '170x127#')
    end
    
    if includeDefault
      #Return default poster
      return Vish::Application.config.full_domain + "/assets/videos/default_poster_image.jpg"
    else
      nil
    end
  end
                      
  def as_json(options = nil)   
    {
      :id => id,
      :type => "video",
      :title => title,
      :description => description,
      :author => author.name,
      :poster => self.poster_url,
      :src => self.source_url,
      :sources => self.sources
    }
  end
  
end
