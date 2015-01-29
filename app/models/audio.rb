class Audio < Document  
  has_attached_file :file, 
                    :url => '/:class/:id.:content_type_extension',
                    :path => ':rails_root/documents/:class/:id_partition/:style',
                    :styles => SocialStream::Documents.audio_styles,
                    :processors => [ :ffmpeg, :waveform ]
  
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
    mimetype = Mime::Type.lookup_by_extension(format_symbol).to_s
    {format: format_symbol, type: mimetype, src: Vish::Application.config.full_domain + Rails.application.routes.url_helpers.audio_path(self, :format => format_symbol)}
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
    #Entry example: {:format=>:mp3, :type=>"audio/mpeg", :src=>"http://localhost:3000/audios/5516.mp3"}
    
    if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
      audio_formats = SocialStream::Documents.audio_styles.map{|k,v| k}
      audio_formats.each do |format_symbol|
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

  def as_json(options = nil)
    {
      :id => id,
      :type => "audio",
      :title => title,
      :description => description,
      :author => author.name,
      :src => self.source_url,
      :sources => self.sources
    }
  end
  
end
