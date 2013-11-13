class Swf < Document  
  has_attached_file :file, 
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'
  
  define_index do
    activity_object_index

    indexes file_file_name, :as => :file_name
  end 
              
  # Thumbnail file
  def thumb(size, helper)
      "#{ size.to_s }/audio.png"
  end

  def as_json(options)
    super.merge!({
      :src => options[:helper].polymorphic_url(self, format: format)
    })
  end
  
end
