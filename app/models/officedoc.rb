class Officedoc < Document  
  has_attached_file :file,
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'

  # Thumbnail file
  def thumb(size, helper)
    "#{ size.to_s }/officedoc.png"
  end

  def source_full_url
    Vish::Application.config.full_domain + self.file.url
  end

  def google_doc_url
    "http://docs.google.com/viewer?url=" + source_full_url + "&embedded=true"
  end

end
