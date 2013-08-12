class Picture < Document
  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:style',
                    :styles => {:timeline  => ["75x75#"],
                                :preview => ["500>"]
                               }                              
                               
  define_index do
    activity_object_index

    indexes file_file_name, :as => :file_name
  end    

  # Thumbnail file
  def thumb(size, helper)
    case size
      when 75
        helper.picture_path self, :format => format, :style => 'timeline'
      when 500
        helper.picture_path self, :format => format, :style => 'preview'
      when 1000
        helper.picture_path self, :format => format, :style => 'original'
    end
  end
      
end
