class Video < Document  
  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :default_url => 'missing_:style.png',
                    :path => ':rails_root/documents/:class/:id_partition/:style',
                    :styles => {
                      :webm => {:format => 'webm'},
                      :flv  => {:format => 'flv'},
                      :mp4  => {:format => 'mp4'},
                      :poster  => {:format => 'png', :time => 5},
                      :timelinesq  => {:geometry => "75x75#" , :format => 'png', :time => 5},
                      :timeline => {:geometry => "100x75#", :format => 'png', :time => 5}
                    },
                    :processors => [:ffmpeg]
                    
  process_in_background :file
  
  define_index do
    activity_object_index

    indexes file_file_name, :as => :file_name
  end
                      
  # Thumbnail file
  def thumb(size, helper)
    case size
      when 75
        helper.picture_path self, :format => format, :style => 'timelinesq'
      when 100
        helper.picture_path self, :format => format, :style => 'timeline'
      when 500
        helper.picture_path self, :format => format, :style => 'poster'
    end
  end

 # JSON, special edition for video files
  def as_json(options = nil)
    {:id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :poster => file(:poster).to_s,
     :sources => [ { :type => Mime::WEBM.to_s,  :src => documents_hostname + ("/" unless file(:webm).to_s.start_with? '/') + file(:webm).to_s },
                   { :type => Mime::MP4.to_s,   :src => documents_hostname + ("/" unless file(:mp4).to_s.start_with? '/') + file(:mp4).to_s },
                   { :type => Mime::FLV.to_s, :src => documents_hostname + ("/" unless file(:flv).to_s.start_with? '/') + file(:flv).to_s }
                 ]
    }
  end
  
end
