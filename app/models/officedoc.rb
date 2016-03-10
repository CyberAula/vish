class Officedoc < Document  
  has_attached_file :file,
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'

  # Thumbnail file
  def thumb(size, helper)
    "#{ size.to_s }/officedoc.png"
  end

  def source_full_url(protocol)
    Embed.checkUrlProtocol(Vish::Application.config.full_domain + self.file.url, protocol)
  end

  def google_doc_url(protocol)
    "https://docs.google.com/viewer?url=" + self.source_full_url(protocol) + "&embedded=true"
  end

end
